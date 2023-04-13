/**
 *Submitted for verification at testnet.snowtrace.io on 2023-04-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
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

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}
contract Access {

/////////////////////EVENTS///////////////////

    event RoleRevoked(bytes32 indexed role,address indexed account, address indexed admin);
    event RoleGranted(bytes32 indexed role,address indexed account, address indexed admin);

/////////////////////STRUCTURES////////////////////////

    struct Roledata{
        mapping(address => bool) members;
        bytes32 role;
    }

/////////////////////VARIABLES///////////////////////////

    address private sig_wallet_admin;  // define the sig wallet
    bytes32 public constant patient_role = keccak256("patient");
    bytes32 public constant doctor_role = keccak256("doctor");
    bytes32 public constant nurse_role = keccak256("nurse");
    bytes32 public constant directeur_role = keccak256("directeur");
    bytes32 public constant admin_role = keccak256("admin");

    mapping(bytes32 => Roledata) private _roles;

    constructor() {
        sig_wallet_admin = msg.sender;
        _roles[admin_role].members[sig_wallet_admin] = true;
    }

////////////////////MODIFIER////////////////////////////

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    function _checkRole(bytes32 role) internal view {
        _checkRole(role, _msgSender());
    }

    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

////////////////////////ADMIN FUNCTIONS////////////////////////////////////////

    function grantRoles(bytes32[] memory role, address[] memory account) internal onlyRole(admin_role) {
        require(role.length == account.length, "Roles and account lengths are not equal");
        for (uint i = 0; i < role.length; i++){
            require(role[i] != admin_role, "role should not be admin");
            require(role[i] == nurse_role || role[i] == doctor_role || role[i] == directeur_role, "role should be nurse doctor or directeur");
            _grantRole(role[i], account[i]);
        }
    }

    function revokeRoles(bytes32[] memory role, address[] memory account) internal onlyRole(admin_role) {
        require(role.length == account.length, "Roles and account lengths are not equal");
        for (uint i = 0; i < role.length; i++){
            require(role[i] != admin_role, "role should not be admin");
            require(role[i] == nurse_role || role[i] == doctor_role || role[i] == directeur_role, "role should be nurse doctor or directeur");
            _revokeRole(role[i], account[i]);
        }
    }

    function grantRole(bytes32 role, address account) internal onlyRole(admin_role) {
        require(role != admin_role, "role should not be admin");
        require(role == nurse_role || role == doctor_role || role == directeur_role, "role should be nurse doctor or directeur");
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) internal onlyRole(admin_role) {
        require(role != admin_role, "role should not be admin");
        require(role == nurse_role || role == doctor_role || role == directeur_role, "role should be nurse doctor or directeur");
        _revokeRole(role, account);
    }

///////////////////////////INTERNAL ADMIN FUNCTION///////////////////////////////

    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}
contract Hospital is Access{
        

    event memberadded(address indexed admin, string indexed newmember_CIN, string indexed newmember_role);
    event hospitaladded(address indexed admin, string indexed hospitalname, uint256 id);


    struct Surgeries{
        uint256 date;
        uint256 hosp_id;
        string description;
        string doctor_CIN;
    }

    struct Datedescription{
        uint256 date;
        string description;
    }

    struct MedicationDate{
        uint256 date;
        uint256 hosp_id;
        string[] medics;
        string CIN_doctor;
    }

    struct Hosp {
        uint256 id;
        string name;
        string adrs;
        string city;
    }

    struct Info {
        address account;
        string CIN;
        string Fname;
        string lname;
        string photo;
        string dateofbirth;
        string gender;
        string adrs;
        string phone;
        string role;
    }
    
    struct  HealthStatus{
        uint256 date;
        string bloodpressure;
        uint256 heartrate; // in bpm
        uint256 weight; // in kg
        uint256 height; // in cm
    }

    struct Records {
        string blood;
        string assurance;
        Datedescription[] medicalhistory;
        Datedescription[] vaccines;
        MedicationDate[] medications;
        HealthStatus[] healthstatus;
        Surgeries[] surgeries;
    }

    uint256 hospitalcount;
    mapping(uint256 => Hosp) hospitals;
    mapping(string => Records) patientrecords;
    mapping(string => Info) member;
    mapping(address => string) employee;


///////////////////Setter functions//////////////////////////

///////BATCH HOSPITAL

    function setnewHospitals(string[] memory _name, string[] memory _adrs, string[] memory _city) external onlyRole(admin_role){
        require(_name.length == _adrs.length && _adrs.length == _city.length);
        for (uint i = 0; i < _name.length; i++){
            setnewHospital(_name[i], _adrs[i], _city[i]);
        }
    }


///////SIMPLE HOSPITAL

    function setnewHospital(string memory _name,string memory _adrs, string memory _city) public onlyRole(admin_role) {
        uint256 _id = hospitalcount;
        Hosp memory hospital = Hosp(_id, _name, _adrs, _city);
        hospitals[_id] = hospital;
        hospitalcount++;
        emit hospitaladded(_msgSender(), _name, _id);
    }

//////BATCH PATIENTS

    function addnewpatients(string[] memory _CIN,
                            string[] memory _fname, 
                            string[] memory _lname,
                            string[] memory _photo,
                            string[] memory _dateofbirth, 
                            string[] memory _gender,
                            string[] memory _adrs, 
                            string[] memory _phone)
                            external onlyRole(admin_role){
        require(_CIN.length == _fname.length && 
                _fname.length == _lname.length &&
                _lname.length == _dateofbirth.length &&
                _dateofbirth.length == _gender.length &&
                _gender.length == _adrs.length &&
                _adrs.length == _phone.length);
        for (uint i = 0; i < _CIN.length; i++){
            addnewpatient(  _CIN[i],
                            _fname[i],
                            _lname[i],
                            _photo[i],
                            _dateofbirth[i],
                            _gender[i],
                            _adrs[i],
                            _phone[i]);
        }
    }

///////BATCH EMPLOYEES

    function addnewemployees(   address[] memory _account,
                                string[] memory _CIN,
                                string[] memory _fname, 
                                string[] memory _lname,
                                string[] memory _photo,
                                string[] memory _dateofbirth, 
                                string[] memory _gender,
                                string[] memory _adrs, 
                                string[] memory _phone,
                                string[] memory _role)
                            external onlyRole(admin_role){
        require(_CIN.length == _fname.length && 
                _fname.length == _lname.length &&
                _lname.length == _dateofbirth.length &&
                _dateofbirth.length == _gender.length &&
                _gender.length == _adrs.length &&
                _adrs.length == _phone.length);
        for (uint i = 0; i < _CIN.length; i++){
            addnewemployee( _account[i],
                            _CIN[i],
                            _fname[i], 
                            _lname[i],
                            _photo[i],
                            _dateofbirth[i], 
                            _gender[i], 
                            _adrs[i], 
                            _phone[i], 
                            _role[i]);
        }
    }

///// SIMPLE PATIENT

    function addnewpatient( string memory _CIN,
                            string memory _fname,
                            string memory _lname,
                            string memory _photo,
                            string memory _dateofbirth,
                            string memory _gender,
                            string memory _adrs,
                            string memory _phone) 
                            public onlyRole(admin_role){
        _addnewMember(address(0), _CIN, _fname, _lname, _photo, _dateofbirth, _gender, _adrs, _phone, "patient"); // patient has no account
    }


///// SIMPLE EMPLOYEES

    function addnewemployee(address _account,
                            string memory _CIN,
                            string memory _fname,
                            string memory _lname,
                            string memory _photo,
                            string memory _dateofbirth,
                            string memory _gender,
                            string memory _adrs,
                            string memory _phone,
                            string memory _role)  
                            public onlyRole(admin_role){
        _addnewMember(_account, _CIN, _fname, _lname, _photo, _dateofbirth, _gender, _adrs, _phone, _role);
        bytes32 therole = keccak256(abi.encodePacked(_role));
        employee[_account] = _CIN;
        grantRole(therole, _account);
    }

/////// ADD employee or patient internal functions


/////// RECORDS PUBLIC FUNCTIONS NOW

    function addmedicalhistorynow(string memory _CIN, string memory _description) public{
        addmedicalhistory(_CIN, block.timestamp, _description);
    }

    function addvaccinenow(string memory _CIN, string memory _description) public{
        addvaccine(_CIN, block.timestamp, _description);
    }

    function addmedicationsnew(string memory _CIN, uint256 _hosp_id, string[] memory _medics) public{
        addmedications(_CIN, block.timestamp, _hosp_id, _medics);
    }

    function addsurgeriesnew(string memory _CIN, uint256 _hosp_id, string memory _descritption) public{
        addsurgeries( _CIN, block.timestamp, _hosp_id, _descritption);
    }

    function addhealthstatusnow(string memory _CIN, string memory _bloodpressure, uint256 _heartrate, uint256 _weight, uint256 _height) public{
        addhealthstatus(_CIN, block.timestamp , _bloodpressure, _heartrate, _weight, _height);
    }
/////// RECORDS PUBLIC FUNCTIONS

    function addrecordsinfo(string memory _CIN,string memory _blood, string memory _assurance ) public { 
        require(hasRole(doctor_role, msg.sender) || hasRole(nurse_role, msg.sender));
        patientrecords[_CIN].blood = _blood;
        patientrecords[_CIN].assurance = _assurance;
        //+ add event
    }

    function addmedicalhistory(string memory _CIN, uint256 _date, string memory _description) public {
        require(hasRole(doctor_role, msg.sender) || hasRole(nurse_role, msg.sender));
        Datedescription memory history = Datedescription(_date, _description);
        patientrecords[_CIN].medicalhistory.push(history);
        //+ add event
    }

    function addvaccine(string memory _CIN, uint256 _date, string memory _description) public {
        require(hasRole(doctor_role, msg.sender) || hasRole(nurse_role, msg.sender));
        Datedescription memory history = Datedescription(_date, _description);
        patientrecords[_CIN].vaccines.push(history);
        //+ add event
    }

    function addmedications(string memory _CIN, uint256 _date, uint256 _hosp_id, string[] memory _medics) public onlyRole(doctor_role) {
        string memory _CIN_doctor = getemployeebyaddress(msg.sender);
        MedicationDate memory medications = MedicationDate(_date , _hosp_id, _medics, _CIN_doctor);
        patientrecords[_CIN].medications.push(medications);
    }

    function addhealthstatus(string memory _CIN, uint256 _date, string memory _bloodpressure, uint256 _heartrate, uint256 _weight, uint256 _height) public {
        require(hasRole(doctor_role, msg.sender) || hasRole(nurse_role, msg.sender));
        HealthStatus memory health = HealthStatus(_date, _bloodpressure, _heartrate, _weight, _height);
         patientrecords[_CIN].healthstatus.push(health);
         //+ add event
    }

    function addsurgeries(string memory _CIN, uint256 _date, uint256 _hosp_id, string memory _descritption) public onlyRole(doctor_role) {
        string memory _CIN_doctor = getemployeebyaddress(msg.sender);
        Surgeries memory surgery = Surgeries(_date, _hosp_id, _descritption, _CIN_doctor);
        patientrecords[_CIN].surgeries.push(surgery);
    }

////////////GET FUNCTIONS////////////////

    function getemployeebyaddress(address _account) public view returns(string memory){
        string memory employee_= employee[_account];
        return employee_;
    }

    function getpatientinfo(string memory _CIN) public view returns(string memory patient_CIN,
                                                                    string memory patient_fname,
                                                                    string memory patient_lname,
                                                                    string memory patient_photo,
                                                                    string memory patient_dateofbirth,
                                                                    string memory patient_gender,
                                                                    string memory patient_adrs,
                                                                    string memory patient_phone){ //+ add access management
        Info memory member_info = member[_CIN];
        patient_CIN = member_info.CIN;
        patient_fname = member_info.Fname;
        patient_lname = member_info.lname;
        patient_photo = member_info.photo;
        patient_dateofbirth = member_info.dateofbirth;
        patient_gender = member_info.gender;
        patient_adrs = member_info.adrs;
        patient_phone = member_info.phone;
        require(hasRole(doctor_role, _msgSender()) || hasRole(nurse_role, _msgSender()) ); //+ to modify
        require(bytes(member_info.CIN).length != 0, "Patient does not exist");
    }

    function getmemberinfo(string memory _CIN) public view returns (address member_account,
                                                                    string memory member_CIN,
                                                                    string memory member_fname,
                                                                    string memory member_lname,
                                                                    string memory member_photo,
                                                                    string memory member_dateofbirth,
                                                                    string memory member_gender,
                                                                    string memory member_adrs,
                                                                    string memory member_phone,
                                                                    string memory member_role){ //+ Add access management
        Info memory member_info = member[_CIN];
        member_account = member_info.account;
        member_CIN = member_info.CIN;
        member_fname = member_info.Fname;
        member_lname = member_info.lname;
        member_photo = member_info.photo;
        member_dateofbirth = member_info.dateofbirth;
        member_gender = member_info.gender;
        member_adrs = member_info.adrs;
        member_phone = member_info.phone;
        member_role = member_info.role;
        require(hasRole(directeur_role, _msgSender()) || hasRole(admin_role, _msgSender())); //+ to modify //+ admin
        require(bytes(member_info.CIN).length != 0, "Member does not exist");


    }





    function _gethospital(uint256 _id) internal view returns(Hosp memory) {
        return hospitals[_id];
    }


    function _getmember(string memory _CIN) internal view returns(Info memory) {
        return member[_CIN];
    }



    function getMedicalRecord(string memory _CIN) public view returns(Records memory patient_records){ //+ doctor nurse
        patient_records = patientrecords[_CIN];
    }

    function getMedicalHistory(string memory _CIN) public view returns(Datedescription[] memory patient_medicalhistory){ //+ doctor nurse
        patient_medicalhistory = patientrecords[_CIN].medicalhistory;
    }

    function getVaccineInfo(string memory _CIN) public view returns(Datedescription[] memory patient_vaccines){ //+ doctor nurse
        patient_vaccines = patientrecords[_CIN].vaccines;
    }    

    function getMedicationsInfo(string memory _CIN) public view returns(MedicationDate[] memory patient_medications){ //+ doctor nurse
        patient_medications = patientrecords[_CIN].medications;
    }

    function getSurgeriesInfo(string memory _CIN) public view returns(Surgeries[] memory patient_surgeries){ //+ doctor nurse
        patient_surgeries = patientrecords[_CIN].surgeries;
    }
////////////Private functions//////////////////

    function _addnewMember( address _account,
                            string memory _CIN,
                            string memory _fname, 
                            string memory _lname,
                            string memory _photo,
                            string memory _dateofbirth, 
                            string memory _gender,
                            string memory _adrs, 
                            string memory _phone,
                            string memory _role)
                            private{

        Info memory newmember = Info(_account, _CIN, _fname, _lname, _photo, _dateofbirth, _gender, _adrs, _phone, _role);
        member[_CIN] = newmember;
        emit memberadded(_msgSender(), _CIN, _role);
    }

}