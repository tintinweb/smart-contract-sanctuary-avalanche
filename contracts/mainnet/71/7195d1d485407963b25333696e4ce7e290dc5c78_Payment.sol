/**
 *Submitted for verification at snowtrace.io on 2022-06-06
*/

// Sources flattened with hardhat v2.9.4 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT
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


// File @openzeppelin/contracts/access/[email protected]
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


// File @openzeppelin/contracts/security/[email protected]
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File @openzeppelin/contracts/utils/[email protected]
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File @openzeppelin/contracts/security/[email protected]
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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

    constructor() {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File contracts/Payment.sol
pragma solidity =0.8.4;




contract Payment is Ownable, Pausable, ReentrancyGuard{

  mapping(string => Chest) public chests;
  bool public allowListActive;
  mapping(address => mapping(string => uint256)) public allowList;
  mapping(string => string) public buyOneGetAnother;

  event ChestBought(string _key, address indexed _buyer, uint indexed _amount);
  event ChestAdded(string _key, uint256 _priceInWei, uint256 _discountPriceInWei, uint256 _totalSupply);
  event ChestUpdated(string _key, uint256 _priceInWei, uint256 _discountPriceInWei, uint256 _totalSupply, uint256 _currentSupply);
  event ChestDeleted(string _key);
  event AllowListActivated();
  event AllowListDeactivated();


  struct Chest{
    uint256 price;
    uint256 discountPrice;
    uint256 totalSupply;
    uint256 currentSupply;
  }

  constructor(){
    AddChest("founder", 35 ether, 35 ether, 4000); // 35000000000000000000
    AddChest("ascended", 3.5 ether, 2.625 ether, 15000); // 3500000000000000000 2625000000000000000

    AddBuyOneGetAnotherPromotion("founder", "ascended");
  }

  function AddChest(string memory _key, uint256 _priceInWei, uint256 _discountPriceInWei, uint256 _totalSupply) public onlyOwner{
    require(chests[_key].totalSupply == 0, "Chest key already exists");
    require(_discountPriceInWei <= _priceInWei, "Discount price should be less or equal to price");
    require(_totalSupply > 0, "Total supply should be greater than zero");

    chests[_key] = Chest({price: _priceInWei, discountPrice: _discountPriceInWei, totalSupply: _totalSupply, currentSupply: 0});
    emit ChestAdded(_key, _priceInWei, _discountPriceInWei, _totalSupply);
  }

  function UpdateChest(string calldata _key, uint256 _priceInWei, uint256 _discountPriceInWei, uint256 _totalSupply, uint256 _currentSupply) external whenPaused onlyOwner{
    require(chests[_key].totalSupply > 0, "Chest key does not exist");
    require(_totalSupply >= _currentSupply, "CurrentSupply should be less than TotalSupply");

    chests[_key] = Chest({price: _priceInWei, discountPrice: _discountPriceInWei, totalSupply: _totalSupply, currentSupply: _currentSupply});
    emit ChestUpdated(_key, _priceInWei, _discountPriceInWei, _totalSupply, _currentSupply);
  }

  function DeleteChest(string calldata _key) external whenPaused onlyOwner{
    require(chests[_key].totalSupply > 0, "Chest key does not exist");
    delete chests[_key];

    emit ChestDeleted(_key);
  }

  function BuyChest(string calldata _key, uint256 _amount) external payable whenNotPaused{
    require(_amount > 0, "Amount should be greater than zero");

    Chest storage chest = chests[_key];
    require(chest.totalSupply > 0, "Chest key does not exist");
    require((chest.currentSupply + _amount) <= chest.totalSupply, "Chest supply is not enough");
    require(isAddressAllowed(msg.sender, _key, _amount), "Address is not in the allow list");
    require(msg.value == CalculateChestsPrice(msg.sender, _key, _amount), "Value sent does not match chest price");

    if(allowListActive){
      SubstractAllowedAmount(msg.sender, _key, _amount);
    }

    chest.currentSupply = chest.currentSupply + _amount;
    emit ChestBought(_key, msg.sender, _amount);
    BuyOneGetAnotherPromotion(_key, _amount);
  }

  // Manage contract balance
  function getBalance() view external onlyOwner returns(uint256){
    return address(this).balance;
  }

  function withdraw() external nonReentrant onlyOwner{
    Address.sendValue(payable(msg.sender), address(this).balance);
  }


  // Allow List
  function ActivateAllowList() public onlyOwner{
    allowListActive = true;
    emit AllowListActivated();
  }

  function DeactivateAllowList() public onlyOwner{
    allowListActive = false;
    emit AllowListDeactivated();
  }

  // Pausable
  function pause() public whenNotPaused onlyOwner{
    _pause();
  }

  function unpause() public whenPaused onlyOwner{
    _unpause();
  }

  function setAllowList(address[] calldata _addresses, string calldata _key, uint256 _amount) external whenPaused onlyOwner {
    
    if(keccak256(abi.encodePacked(_key)) == keccak256(abi.encodePacked("ascended")) && _amount > 0){
      _amount = 20;
    }
    
    for (uint256 i = 0; i < _addresses.length; i++) {
      allowList[_addresses[i]][_key] = _amount;
    }
  }

  function isAddressAllowed(address _addr, string memory _key, uint256 _amount) public view returns(bool){
    return !allowListActive || (allowListActive && allowList[_addr][_key] >= _amount);
  } 

  function SubstractAllowedAmount(address _addr, string memory _key, uint256 _amount) internal{
      allowList[_addr][_key] = allowList[_addr][_key] -_amount;
  }


  // Promotion A: When player bough a Chest gets another one for free
  function AddBuyOneGetAnotherPromotion(string memory _buy, string memory _get) public onlyOwner{
    require(chests[_buy].totalSupply > 0, "Buy chest does not exist");
    require(chests[_get].totalSupply > 0, "Get chest does not exist");

    buyOneGetAnother[_buy] = _get;
  }

  function DeleteBuyOneGetAnotherPromotion(string memory _key) external whenPaused onlyOwner{
    delete buyOneGetAnother[_key];
  }

  function BuyOneGetAnotherPromotion(string memory _key, uint256 _amount) internal{
    // Check if promotions are active
    if(!allowListActive){
      return;
    }    

    // Check if there's a promotion for the chest that the user bought
    if(bytes(buyOneGetAnother[_key]).length == 0){
      return;
    }

    // Check if there's supply for the promotion chest
    Chest storage chest = chests[buyOneGetAnother[_key]];
    uint256 remainingChests = chest.totalSupply - chest.currentSupply;

    if(remainingChests == 0){
      return;
    }

    if(remainingChests < _amount){
      chest.currentSupply = chest.currentSupply + remainingChests;
      emit ChestBought(buyOneGetAnother[_key], msg.sender, remainingChests);
    }else{
      chest.currentSupply = chest.currentSupply + _amount;
      emit ChestBought(buyOneGetAnother[_key], msg.sender, _amount);
    }

  }

  function CalculateChestsPrice(address _address, string memory _key, uint256 _amount) public view returns(uint256) {

    Chest storage chest = chests[_key];

    // Check is allow list is active
    if(allowListActive){
      // Check if the chest bought is an Ascended
      if( keccak256(abi.encodePacked(_key)) == keccak256(abi.encodePacked("ascended")) ){

        // Promotion B: When player bought first 2 Ascended, the price will be reduced. 
        if(allowList[_address][_key] > 18){
          uint256 amountDiscounted = allowList[_address][_key] - 18;

          if(_amount > amountDiscounted){
            return chest.discountPrice * amountDiscounted + chest.price * (_amount - amountDiscounted); 
          }
          
          return chest.discountPrice * _amount; 
        }
      }
    }
    
    return chest.price * _amount;
  } 

}