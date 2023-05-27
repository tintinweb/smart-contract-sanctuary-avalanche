/**
 *Submitted for verification at snowtrace.io on 2023-05-27
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-08
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity 0.8.7;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
abstract contract SafeMath {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
 
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IAVAX20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8) ;
    function deposit(uint256 amount) external payable;
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IWAVAX {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address who) external view returns (uint256);
}


contract MultiSig_Claimer is Ownable, SafeMath{
    bool locked;

    struct users {
        address userAddress;
        uint256 userShare;
    }

    users[] public user;

    constructor(){
        locked = false;
        users memory newUser;

		//@mokapott
		newUser.userShare = 10000;
		newUser.userAddress = 0x7Fa8533246Ed3C57e2B2B73DEeeDE073FEf29E22;
        user.push(newUser);
				
		//abavalanche
		newUser.userShare = 10000;
		newUser.userAddress = 0xf4A1BE5ecbB1b3f3BA79cB49664Ae4380C5dE228;
        user.push(newUser);
		
		//Yosimo ◭
		newUser.userShare = 10000;
		newUser.userAddress = 0x01330AD911587424ED2F8a77310C6AFe2e702E2E;
        user.push(newUser);
		
		//@2smallmonkeys
		newUser.userShare = 10000;
		newUser.userAddress = 0xDAc583d152BBC3F4056Ac86313947eDEf97d3a6e;
        user.push(newUser);
		
		//Andre
		newUser.userShare = 10000;
		newUser.userAddress = 0xc429ff93C8479c018d58cC5A1ee2b73756E5B491;
        user.push(newUser);
		
		//@matrixkhey
		newUser.userShare = 5000;
		newUser.userAddress = 0x4aC99941d82CDc26633e9d28A6dDb09cAF46c388;
        user.push(newUser);
				
		//adrotitanique
		newUser.userShare = 5000;
		newUser.userAddress = 0x7e84638EfcF13bb710D591048532AB09990B7c4a;
        user.push(newUser);
		
		///////Allocation initiale Colombus 1500///////
		//Pasteur
		newUser.userShare = 500;
		newUser.userAddress = 0xEC471edC52124dD6142be6F841247DEe98Ab7fD3;
        user.push(newUser);
		
		//MaskD
		newUser.userShare = 500;
		newUser.userAddress = 0xce19a0E832A6c290721c48DC20c9a185dc7151FC;
        user.push(newUser);
		
		//Papy chancla
		newUser.userShare = 500;
		newUser.userAddress = 0x8AE18353fFA561be14f5c6012BF53C194dFDFAA7;
        user.push(newUser);
		///////Allocation initiale Colombus 1500///////
		
		//@JulienProf
		newUser.userShare = 52000;
		newUser.userAddress = 0x80558b521Fc22BE94286A85776D0Ec9469688C93;
        user.push(newUser);
				
		//@RachedR
		newUser.userShare = 2000;
		newUser.userAddress = 0x615BaA9dd5C8eed0D3a800D6835dF07e453Db47e;
        user.push(newUser);
		
		//@Edou666
		newUser.userShare = 20000;
		newUser.userAddress = 0xBCEE5F1A02392608324903fa61e3042dc8a0B641;
        user.push(newUser);

		//@Toinounet21
		newUser.userShare = 50000;
		newUser.userAddress = 0x8964A0A2d814c0e6bF96a373f064a0Af357bb4cE;
        user.push(newUser);
				
		//@Theo_Il
		newUser.userShare = 10000;
		newUser.userAddress = 0x902E6273a0097fE75D22b6047812339832d0Fc8A;
        user.push(newUser);
		
		//@fril69
		newUser.userShare = 5000;
		newUser.userAddress = 0x432D181B4D4D387a1591c1E9124366aD0e7EC818;
        user.push(newUser);
		
		//@RikuRC
		newUser.userShare = 10000;
		newUser.userAddress = 0x3d8E6A772952408175E52ebbD49564267d134625;
        user.push(newUser);
		
		//@papacrypto33
		newUser.userShare = 11500;
		newUser.userAddress = 0xE972E34efF5b1C3D6FE07e13DAC3E482e70A3E9d;
        user.push(newUser);
		
		//Kaneda shotaro
		newUser.userShare = 500;
		newUser.userAddress = 0x8Df9CFb2E250f4FD281e4577C921b3DAa672687C;
        user.push(newUser);
		
		//Smith
		newUser.userShare = 9500;
		newUser.userAddress = 0x61209667eb1859b7946662aD47A7728e0107c5d7;
        user.push(newUser);
		
		//Livai
		newUser.userShare = 5000;
		newUser.userAddress = 0x2a17460766b1e4984eE90E1e6312C7EAa25fabBB;
        user.push(newUser);
		
		//@all3kcis
		newUser.userShare = 1000;
		newUser.userAddress = 0x4D659F486013A5752d518b675CEf848dCeC1726E;
        user.push(newUser);
		
		//David D
		newUser.userShare = 3000;
		newUser.userAddress = 0xCb21b62CB62d02b61577D4f5edBbf1e56263d3d4;
        user.push(newUser);
		
		//@quentincl
		newUser.userShare = 1000;
		newUser.userAddress = 0xff8Ad1eD6d071f4485730217F18C48F09aa577D4;
        user.push(newUser);
		
		//el_cy
		newUser.userShare = 8000;
		newUser.userAddress = 0x9f03b0de71357829Cf5316De0A49C5A1A9c73F31;
        user.push(newUser);
    }
    
    function addUser(address userAddress, uint256 userShare) external onlyOwner{
        if(locked == false){
            users memory newUser;
            newUser.userAddress = userAddress;
            newUser.userShare = userShare;
            user.push(newUser);
        }
        else{
            revert("Contract Locked!");
        }
    }

    function userCount() public view returns(uint256 length) {
        return user.length;
    }

    function getUser(uint256 index) public view returns(address userAddress, uint256 userShare){
        return (user[index].userAddress, user[index].userShare);
    }

    function totalShare() public view returns (uint256 total){
        uint256 totalAmount;
        for(uint i = 0; i < user.length; i++){
            totalAmount += user[i].userShare;
        }
        return totalAmount;
    }
    
    function claimer(address token, address multisig) external onlyOwner() {
        if(locked == true){
            uint256 balance = IAVAX20(token).balanceOf(multisig);
            for(uint i = 0; i < user.length; i++){
                uint256 share = user[i].userShare;
                uint256 total = totalShare();
                uint256 amountPaid = mul(div(balance, 10000), div(mul(share, 10000), total));
                IAVAX20(token).transferFrom(multisig, user[i].userAddress, amountPaid);
            }
            uint8 decimalsToken = IAVAX20(token).decimals();
            if(IAVAX20(token).balanceOf(multisig) < 1*10**decimalsToken){
                IAVAX20(token).transferFrom(multisig, msg.sender, IAVAX20(token).balanceOf(multisig));
            }
            else{
                revert("Too Many Tokens Remaining");
            }
        }
        else{
            revert("Contract must be Locked!");
        }
    }

    function lock() external onlyOwner() {
        require(locked == false);
        locked = true;
    }

}