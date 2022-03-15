/**
 *Submitted for verification at snowtrace.io on 2022-03-15
*/

//SPDX-License-Identifier: UNLICENSED
/**
 *Submitted for verification at FtmScan.com on 2021-10-25
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;


    /* --------- safe math --------- */
library SafeMath {
	/**
	* @dev Returns the addition of two unsigned integers, reverting on
	* overflow.
	*
	* Counterpart to Solidity's `+` operator.
	*
	* Requirements:
	* - Addition cannot overflow.
	*/
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");

		return c;
	}

	/**
	* @dev Returns the subtraction of two unsigned integers, reverting on
	* overflow (when the result is negative).
	*
	* Counterpart to Solidity's `-` operator.
	*
	* Requirements:
	* - Subtraction cannot overflow.
	*/
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	/**
	* @dev Returns the subtraction of two unsigned integers, reverting with custom message on
	* overflow (when the result is negative).
	*
	* Counterpart to Solidity's `-` operator.
	*
	* Requirements:
	* - Subtraction cannot overflow.
	*/
	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;

		return c;
	}

	/**
	* @dev Returns the multiplication of two unsigned integers, reverting on
	* overflow.
	*
	* Counterpart to Solidity's `*` operator.
	*
	* Requirements:
	* - Multiplication cannot overflow.
	*/
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
		if (a == 0) {
		return 0;
		}

		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");

		return c;
	}

	/**
	* @dev Returns the integer division of two unsigned integers. Reverts on
	* division by zero. The result is rounded towards zero.
	*
	* Counterpart to Solidity's `/` operator. Note: this function uses a
	* `revert` opcode (which leaves remaining gas untouched) while Solidity
	* uses an invalid opcode to revert (consuming all remaining gas).
	*
	* Requirements:
	* - The divisor cannot be zero.
	*/
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, "SafeMath: division by zero");
	}

	/**
	* @dev Returns the integer division of two unsigned integers. Reverts with custom message on
	* division by zero. The result is rounded towards zero.
	*
	* Counterpart to Solidity's `/` operator. Note: this function uses a
	* `revert` opcode (which leaves remaining gas untouched) while Solidity
	* uses an invalid opcode to revert (consuming all remaining gas).
	*
	* Requirements:
	* - The divisor cannot be zero.
	*/
	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		// Solidity only automatically asserts when dividing by 0
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	/**
	* @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	* Reverts when dividing by zero.
	*
	* Counterpart to Solidity's `%` operator. This function uses a `revert`
	* opcode (which leaves remaining gas untouched) while Solidity uses an
	* invalid opcode to revert (consuming all remaining gas).
	*
	* Requirements:
	* - The divisor cannot be zero.
	*/
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}

	/**
	* @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	* Reverts with custom message when dividing by zero.
	*
	* Counterpart to Solidity's `%` operator. This function uses a `revert`
	* opcode (which leaves remaining gas untouched) while Solidity uses an
	* invalid opcode to revert (consuming all remaining gas).
	*
	* Requirements:
	* - The divisor cannot be zero.
	*/
	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}


interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

	function mint( address to, uint256 amount) external ;
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor()  {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/* --------- Access Control --------- */

contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract Presale is Ownable {

    using SafeMath for uint256;

    event Buy(address buyerAddress, uint256 amount);
  
    address private aomTokenAddress;
    uint256 private startTime;
    uint256 private tokenPrice; // aom amount per usdc or dai
    uint256 private presalePeriod;
    mapping (address => bool) private whitelist;
    uint256 public daiDecimal = 18;
    uint256 public usdcDecimal = 6;
    uint256 public aomDecimal = 9;
    address public daiAddress = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
    address public usdcAddress = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    
    constructor (
        address aomTokenAddress_,
        uint256 tokenPrice_,
        uint256 presalePeriod_
    )  {
        aomTokenAddress = aomTokenAddress_;
        tokenPrice = tokenPrice_;
        presalePeriod = presalePeriod_;
        startTime = block.timestamp;
        whitelist[msg.sender] = true;
    }

    function buyWithUsdc( uint256 amount) external {
        
        require(block.timestamp <= (startTime + presalePeriod), "Presale Finished");

        uint256 mintAmount = amount.mul(10**aomDecimal).div(tokenPrice).div(10**usdcDecimal);    
            
        if(whitelist[msg.sender] == true){
            IERC20(aomTokenAddress).mint(msg.sender, mintAmount ); 
        } else {
            require(IERC20(usdcAddress).balanceOf(msg.sender) >= amount, "balance not enough");
            IERC20(usdcAddress).transferFrom( msg.sender , address(this) , amount);
            IERC20(aomTokenAddress).mint(msg.sender, mintAmount ); 
        }
        
        emit Buy(msg.sender, amount);
    }

    function buyWithDai (uint256 amount) external {

        require(block.timestamp <= (startTime + presalePeriod), "Presale Finished");

        uint256 mintAmount = amount.mul(10**aomDecimal).div(tokenPrice).div(10**daiDecimal);

        if(whitelist[msg.sender] == true){
            IERC20(aomTokenAddress).mint(msg.sender, mintAmount );     
        } else {
            require(IERC20(daiAddress).balanceOf(msg.sender) >= amount, "balance not enough");
            IERC20(daiAddress).transferFrom( msg.sender , address(this) , amount);
            IERC20(aomTokenAddress).mint(msg.sender, mintAmount ); 
        }
        
        emit Buy(msg.sender, amount);
    }

    function claimUsdcToken( uint256 amount )
        external
        onlyOwner
    {
        IERC20(usdcAddress).transfer(owner(), amount);
    }

    function claimDaiToken( uint256 amount )
        external
        onlyOwner
    {
        IERC20(usdcAddress).transfer(owner(), amount);
    }


    function getPrice() public view returns (uint tokenPrice_) {
        return tokenPrice;
    }

    function setPrice(uint256 tokenPrice_ ) external onlyOwner() {
        tokenPrice = tokenPrice_;
    }

    function setPeriod(uint256 presalePeriod_) external onlyOwner() {
        presalePeriod = presalePeriod_;
    }

    function setWhitelist ( address _addr) external onlyOwner() {
        whitelist[_addr] = true;
    }
}