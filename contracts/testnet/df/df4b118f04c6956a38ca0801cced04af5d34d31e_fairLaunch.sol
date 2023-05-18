/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-18
*/

//SPDX-License-Identifier: UNLICENSED 

pragma solidity 0.6.12;

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

    function _msgData() internal pure returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor()  public {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


interface IToken {
  function remainingMintableSupply() external view returns (uint256);
  function calculateTransferTaxes(address _from, uint256 _value) external view returns (uint256 adjustedValue, uint256 taxAmount);
  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);
  function deposit() external payable;
  function transfer(address to, uint256 value) external returns (bool);
  function balanceOf(address who) external view returns (uint256);
  function mintedSupply() external returns (uint256);
  function allowance(address owner, address spender)
  external
  view
  returns (uint256);
  function approve(address spender, uint256 value) external returns (bool);
    function whitelist(address addrs) external returns(bool);
    function addAddressesToWhitelist(address[] memory addrs)  external returns(bool success) ;
}

contract fairLaunch is Ownable, ReentrancyGuard {
    
        IToken public weth;
        mapping(address => uint256) public amountBought;
        mapping(address => uint256) public referralEarned;
        uint256 public tokensForSale = 430000e18;
        uint256 public totalReferral;
        event Pause();
        event Unpause();
        bool public paused;
        bool public init = false;
        receive() external payable {}


    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data);

    function tokenPrice() public view returns(uint256) {
        uint256 totalBalance = weth.balanceOf(address(this)) + totalReferral;
        uint256 tokenAmount = tokensForSale * 1e18;
        uint256 tokenPriceLocal = ( tokenAmount / totalBalance);
        return tokenPriceLocal;
    }

    function userTokenAmount(address user) public view returns(uint256) {
        uint256 localTokenPrice = tokenPrice();
        uint256 userEther = amountBought[user];
        uint256 allocatedTokensUser =  userEther * localTokenPrice;
        uint256 allocatedTokensUserToEth = allocatedTokensUser / 1e18;
        return allocatedTokensUserToEth;
    }

    modifier initializer() {
        require(init == false, "only one time");
        _;
    }

    function initialize(address weth_addr) public initializer {
        weth = IToken(weth_addr);
        init = true;
        paused = false;
    }
  
    function pause() onlyOwner public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner public {
        paused = false;
        emit Unpause();
    }

    function Buy(address referral) public payable nonReentrant {
        require(referral != address(0), "Referral address cannot be null");
        require(referral != msg.sender, "Referral address cannot be null");
        require(paused == false , "contract is paused" );
        uint256 amount = msg.value;
        (bool success, ) = payable(address(this)).call{value: msg.value}("");
        require(success, "Failed to send ether to contract");

    if (referral != address(this)) {

        // paying out referral
        uint256 referralAmountNow = (amount * 5) / 100;
        totalReferral = totalReferral + referralAmountNow;
        payable(referral).transfer(referralAmountNow);
        //  for stats
        referralEarned[referral] = referralEarned[referral] + referralAmountNow;
    }

        uint256 allETH = address(this).balance;
        IToken(weth).deposit{value: allETH}();
        uint256 amountBoughtNow = amountBought[msg.sender];
        amountBought[msg.sender] = amountBoughtNow + amount;
    }

    function checkContractBalance() public view returns(uint256) {
        return weth.balanceOf(address(this));
    }

    function sendCustomTransaction(address target, uint value, string memory signature, bytes memory data) public payable onlyOwner returns (bytes memory)  {
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data));
        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data);

        return returnData;
    }

}