/**
 *Submitted for verification at snowtrace.io on 2022-07-22
*/

// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* ERC20 and ERC20P (following ERC712) */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
}

/* ERC712 permit interface */
interface IERC20P is IERC20 {
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}
interface IERC20W is IERC20 {
    function wrap(uint amount) external returns (bool);
    function unwrap(uint amount) external returns (bool);
    function recover(address account) external returns (uint value);
    function airdrop(address[] memory account, uint amount) external;
}


// File: @openzeppelin/contracts/utils/Context.sol
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// File: @openzeppelin/contracts/access/Ownable.sol
pragma solidity ^0.8.0;
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function operator() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(operator() == _msgSender(), "Ownable: caller is not the operator");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/* simple permit extension */
contract ERC20PW is IERC20P, IERC20W, Ownable {

    /* underlying token and name and symbol set in constructor*/
    IERC20 public immutable underlying;    
    string public name;
    string public symbol;

    /* force 18 decimals */
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;    
    mapping(address => mapping(address => uint256)) public allowance;

    /* the permit typehash is constant */
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
	0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;


    /* function DOMAIN_SEPARATOR() public view returns (bytes32) { */
    /* 	return keccak256( */
    /* 		  abi.encode( */
    /* 			     keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"), */
    /* 			     keccak256(bytes(name)), */
    /* 			     keccak256(bytes("1")), */
    /* 			     block.chainid, */
    /* 			     address(this) */
    /* 			     ) */
    /* 		  ); */
    /* } */

    /* computed locally by deployer and initialized in constructor */
    bytes32 public immutable DOMAIN_SEPARATOR;
    
    /* to stop "double spending" of permits. */
    /* every address starts off with nonce zero */
    /* unrelated to the global nonce */
    mapping(address => uint256) public nonces;
    
    constructor(string memory _name,
		bytes32 _DOMAIN_SEPARATOR,
		string memory _symbol,
		IERC20 _underlying) {
	name = _name;
	DOMAIN_SEPARATOR = _DOMAIN_SEPARATOR;
	symbol = _symbol;
	underlying = _underlying;
    }
    function permit(
		    address owner,
		    address spender,
		    uint256 value,
		    uint256 deadline,
		    uint8 v,
		    bytes32 r,
		    bytes32 s
		    ) external {
        require(deadline >= block.timestamp, "Permit: EXPIRED");
        bytes32 digest = keccak256(
				   abi.encodePacked(
						    "\x19\x01",
						    DOMAIN_SEPARATOR,
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
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
		recoveredAddress != address(0) && recoveredAddress == owner,
		"Permit: INVALID_SIGNATURE"
		);       
        _approve(owner, spender, value);
    }


    /* underlying mint and burn */
    function _mint(address to, uint256 value) internal {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }   
    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    /* wrap */
    function wrap(uint256 amount) external returns (bool) {
        require(underlying.transferFrom(msg.sender, address(this), amount),"transfer failed");
        _mint(msg.sender, amount);
        return true;
    }
    /* unwrap */
    function unwrap(uint256 amount) external returns (bool) {
	_burn(msg.sender, amount);
	require(underlying.transfer(msg.sender, amount),"transfer failed");
        return true;
    }

    /* recover */
    function recover(address account) external onlyOwner returns (uint value) {
	value = underlying.balanceOf(address(this)) - totalSupply;
        _mint(account, value);
        return value;
    }

    /* airdrop */ 
    function airdrop(address[] memory recipients, uint amount) external {	
	uint256 cost;
	for (uint256 i = 0; i < recipients.length; ++i) {
	    _mint(recipients[i],amount);
	    cost += amount;
	}
	underlying.transferFrom(msg.sender, address(this), cost);
    }
    
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }
    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
	    /* will fail on overflow */
            allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        }
        _transfer(from, to, value);
        return true;
    }

    
}