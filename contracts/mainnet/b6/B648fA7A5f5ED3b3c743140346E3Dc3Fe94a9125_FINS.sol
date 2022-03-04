/**
 *Submitted for verification at snowtrace.io on 2022-03-04
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address from, address to, uint256 amount ) external returns (bool);

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
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/**
 * @title Context
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

/**
 * @title Ownable
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
contract Ownable is Context{
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
    function getOwner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(getOwner() == _msgSender(), "Caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
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

/**
 * @title Freezable
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotFrozen` and `whenFrozen`, which can be applied to
 * the functions of your contract. Note that they will not be freezable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Freezable is Ownable {
    
    
    /**
     * @dev Emitted when the freeze is triggered by `account`.
     */
    event Frozen(address account);

    /**
     * @dev Emitted when the freeze is lifted by `account`.
     */
    event Unfrozen(address account);

    bool private _frozen;
    address[3] private _freezers;
    uint private _freezerCount;

    /**
     * @dev Initializes the contract in unfrozen state.
     */
    constructor() {
        _frozen = false;
        _freezerCount = 0;
    }

    /**
     * @dev Throws if called by any account other than one of the freezer.
     */
    modifier onlyFreezer() {
        require(isFreezer(_msgSender()), "Caller is not the freezer");
        _;
    }

    function isFreezer(address freezer) public view virtual returns (bool) {
        require(freezer != address(0), "Freezer is the zero address");
        return _freezers[0] == freezer || _freezers[1] == freezer || _freezers[2] == freezer;
    }

    function setFreezer(address freezer) external onlyOwner {
        require(freezer != address(0), "New freezer is the zero address");
        require(_freezerCount < 3, "Freezer count reached");
        if (_freezerCount > 0){
            for (uint i=0; i<_freezerCount; i++) {
                require(freezer != _freezers[i], "This freezer is already set");
            }
        }
        _freezers[_freezerCount] = freezer;
        _freezerCount++;
    }

    function updateFreezer(address oldFreezer, address freezer) external onlyOwner{
        require(oldFreezer != address(0), "Old freezer is the zero address");
        require(freezer != address(0), "New freezer is the zero address");
        require(oldFreezer != freezer, "Old and new freezer is same");
        require(!isFreezer(freezer), "New freezer is already set");
        bool executed = false;
        if (_freezers[0] == oldFreezer){
            _freezers[0] = freezer;
            executed = true;
        } else if (_freezers[1] == oldFreezer){
            _freezers[1] = freezer;
            executed = true;
        } else if (_freezers[2] == oldFreezer){
            _freezers[2] = freezer;
            executed = true;
        }
        require(executed, "Old freezer not found");
    }

    /**
     * @dev Returns true if the contract is frozen, and false otherwise.
     */
    function isFrozen() public view virtual returns (bool) {
        return _frozen;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not frozen.
     *
     * Requirements:
     *
     * - The contract must not be frozen.
     */
    modifier whenNotFrozen() {
        require(!isFrozen(), "Freezable: frozen");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is frozen.
     *
     * Requirements:
     *
     * - The contract must be frozen.
     */
    modifier whenFrozen() {
        require(isFrozen(), "Freezable: not frozen");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be frozen.
     */
    function freeze() external onlyFreezer whenNotFrozen {
        _frozen = true;
         emit Frozen(_msgSender());
    }

    
    function unfreeze() external onlyFreezer whenFrozen {
        _frozen = false;
        emit Unfrozen(_msgSender());
    }

}

/**
 * @title Blacklistable Token
 * @dev Allows accounts to be blacklisted by a "blacklister" role
*/
contract Blacklistable is Freezable {

    address[3] private _blacklisters;
    uint private _blacklisterCount;

    mapping(address => bool) internal blacklisted;

    event Blacklisted(address indexed _account);
    event UnBlacklisted(address indexed _account);

    constructor() {
        _blacklisterCount = 0;
    }

    /**
     * @dev Throws if called by any account other than one of the blacklister.
     */
    modifier onlyBlacklister() {
        require(isBlacklister(_msgSender()), "Caller is not the blacklister");
        _;
    }

    function isBlacklister(address blacklister) public view virtual returns (bool) {
        require(blacklister != address(0), "Blacklister is the zero address");
        return _blacklisters[0] == blacklister || _blacklisters[1] == blacklister || _blacklisters[2] == blacklister;
    }

    function setBlacklister(address blacklister) external onlyOwner {
        require(blacklister != address(0), "Blacklister is the zero address");
        require(_blacklisterCount < 3, "Blacklister count reached");
        if (_blacklisterCount > 0){
            for (uint i=0; i<_blacklisterCount; i++) {
                require(blacklister != _blacklisters[i], "This blacklister is already set");
            }
        }
        _blacklisters[_blacklisterCount] = blacklister;
        _blacklisterCount++;
    }

    function updateBlacklister(address oldBlacklister, address blacklister) external onlyOwner{
        require(oldBlacklister != address(0), "Old blacklister is the zero");
        require(blacklister != address(0), "New blacklister is the zero");
        require(oldBlacklister != blacklister, "Old and new blacklister is same");
        require(!isBlacklister(blacklister), "New blacklister is already set");
        bool executed = false;
        if (_blacklisters[0] == oldBlacklister){
            _blacklisters[0] = blacklister;
            executed = true;
        } else if (_blacklisters[1] == oldBlacklister){
            _blacklisters[1] = blacklister;
            executed = true;
        } else if (_blacklisters[2] == oldBlacklister){
            _blacklisters[2] = blacklister;
            executed = true;
        }
        require(executed, "Old blacklister not found");
    }

    

    /**
     * @dev Throws if argument account is blacklisted
     * @param _account The address to check
    */
    modifier notBlacklisted(address _account) {
        require(!blacklisted[_account], "Address is blacklisted");
        _;
    }

    /**
     * @dev Checks if account is blacklisted
     * @param _account The address to check
    */
    function isBlacklisted(address _account) external view returns (bool) {
        return blacklisted[_account];
    }

    /**
     * @dev Adds account to blacklist
     * @param _account The address to blacklist
    */
    function blacklist(address _account) external onlyBlacklister {
        blacklisted[_account] = true;
        emit Blacklisted(_account);
    }

    /**
     * @dev Removes account from blacklist
     * @param _account The address to remove from the blacklist
    */
    function unBlacklist(address _account) external onlyBlacklister {
        blacklisted[_account] = false;
        emit UnBlacklisted(_account);
    }

}


contract StandardToken is IERC20, IERC20Metadata, Blacklistable {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply ;

    string internal _name;
    string internal _symbol;

    function balanceOf(address _addr) public view override returns (uint256 balance) {
        return _balances[_addr];
    }

    function totalSupply() public view override returns (uint256){
        return _totalSupply;
    }

    function transfer(address to, uint256 amount) public virtual override whenNotFrozen notBlacklisted(_msgSender()) notBlacklisted(to) returns (bool success) {
        address balanceOwner = _msgSender();
        _transfer(balanceOwner, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount ) public virtual override whenNotFrozen notBlacklisted(from) notBlacklisted(to) returns (bool){
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount ) internal virtual {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "Transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount ) internal virtual {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override whenNotFrozen notBlacklisted(_msgSender()) notBlacklisted(spender) returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */

    function increaseAllowance(address spender, uint256 addedValue) public virtual whenNotFrozen notBlacklisted(_msgSender()) notBlacklisted(spender) returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }


    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual whenNotFrozen notBlacklisted(_msgSender()) notBlacklisted(spender) returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "Decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    
}


contract FINS is StandardToken {

    event Claim(address claimableAddress, uint256 amount, uint256 claimsCount, address claimer);
    struct ClaimInfo { 
        uint256 nextUnlockTime;
        uint256 claimAmount;
        uint256 claimCount;
   }

    mapping(address => ClaimInfo) private _claimData;
    
    
    bool private _isInitiated = false;

    constructor () {
        uint8 _decimals = decimals();
        uint256 initialSupply = 100_000_000 * 10 ** uint256(_decimals);
        _totalSupply = initialSupply;
        _balances[_msgSender()] = initialSupply;
        _name = "altFINS";
        _symbol = "AFINS";
    }

    function init(address[8] memory claimers) external onlyOwner {
        require(!_isInitiated, "Can only be called once!");

        uint256 currentTime = getCurrentTime();
        uint256 sixMonthsFromNow = currentTime + (86400 * 180);
        uint256 contractTotalAmount = 0;

    // ecoGrowth start
        _claimData[claimers[0]] = ClaimInfo(sixMonthsFromNow, 500_000 * 10 ** uint256(decimals()), 18);
        contractTotalAmount += (_claimData[claimers[0]].claimAmount * 18);
    // comRewards start
        _claimData[claimers[1]] = ClaimInfo(sixMonthsFromNow, 1_200_000 * 10 ** uint256(decimals()), 18);
        contractTotalAmount += (_claimData[claimers[1]].claimAmount * 18);
    // platformDev start
        _claimData[claimers[2]] = ClaimInfo(sixMonthsFromNow, 650_000 * 10 ** uint256(decimals()), 18);
        contractTotalAmount += (_claimData[claimers[2]].claimAmount * 18);
    // exchangeLiq start
        _claimData[claimers[3]] = ClaimInfo(currentTime, 166_666 * 10 ** uint256(decimals()), 6);
        contractTotalAmount += (_claimData[claimers[3]].claimAmount * 6);
    // marketing start
        _claimData[claimers[4]] = ClaimInfo(sixMonthsFromNow, 1_000_000 * 10 ** uint256(decimals()), 18);
        contractTotalAmount += (_claimData[claimers[4]].claimAmount * 18);
    // reserve start
        _claimData[claimers[5]] = ClaimInfo(sixMonthsFromNow, 277_777 * 10 ** uint256(decimals()), 18);
        contractTotalAmount += (_claimData[claimers[5]].claimAmount * 18);
    // advisors start
        _claimData[claimers[6]] = ClaimInfo(sixMonthsFromNow, 111_111 * 10 ** uint256(decimals()), 18);
        contractTotalAmount += (_claimData[claimers[6]].claimAmount * 18);
    // team start
        _claimData[claimers[7]] = ClaimInfo(sixMonthsFromNow, 1_333_333 * 10 ** uint256(decimals()), 18);
        contractTotalAmount += (_claimData[claimers[7]].claimAmount * 18);

    //initial vesting transfer to contract
        _transfer(getOwner(), address(this), contractTotalAmount); // for monthly vesting
    //initial unlock transfers
        _transfer(getOwner(), claimers[0], 1_000_000 * 10 ** uint256(decimals()));
        _transfer(getOwner(), claimers[1], 2_400_000 * 10 ** uint256(decimals()));
        _transfer(getOwner(), claimers[2], 1_300_000 * 10 ** uint256(decimals()));
        _transfer(getOwner(), claimers[3], 1_000_004 * 10 ** uint256(decimals()));
        _transfer(getOwner(), claimers[4], 2_000_000 * 10 ** uint256(decimals()));
        _transfer(getOwner(), claimers[5], 14 * 10 ** uint256(decimals()));
        _transfer(getOwner(), claimers[6], 2 * 10 ** uint256(decimals()));
        _transfer(getOwner(), claimers[7], 6 * 10 ** uint256(decimals()));

        _isInitiated = true;
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function getCurrentClaimData(address claimableAddress) external view returns (ClaimInfo memory)
    {
        return _claimData[claimableAddress];
    }

    function claim(address claimableAddress) external whenNotFrozen notBlacklisted(claimableAddress) returns (bool) {
        require(claimableAddress != address(0), "Claimable address is the zero");
        ClaimInfo memory claimInfo = _claimData[claimableAddress];
        require(claimInfo.claimCount > 0, "Cannot claim");
        uint256 currentTime = getCurrentTime();
        uint256 claimableCount = 0;
        uint256 nextUnlockTime = claimInfo.nextUnlockTime;
        require(nextUnlockTime < currentTime, "Cannot claim yet");
        while(nextUnlockTime < currentTime){
            claimableCount++;
            nextUnlockTime += (86400 * 30); // 1 month (30 days) in seconds
        }
        require(claimableCount > 0, "Nothing to claim");
        
        // for safety reasons (if someone is not claiming at all for 24 month and then will try to claim all at once)
        if (claimableCount > claimInfo.claimCount){
            claimableCount = claimInfo.claimCount;
        }

        claimInfo.nextUnlockTime = nextUnlockTime;
        claimInfo.claimCount -= claimableCount;
        _claimData[claimableAddress] = claimInfo;
        uint256 toClaim = claimableCount * claimInfo.claimAmount;
        _transfer(address(this), claimableAddress, toClaim);
        emit Claim(
            claimableAddress,
            toClaim,
            claimableCount,
            _msgSender()
        );
        return true;
    }

    function updateClaimer(address oldClaimer, address claimer) external onlyOwner{
        require(oldClaimer != address(0), "Old claimer is the zero");
        require(claimer != address(0), "New claimer is the zero");
        require(oldClaimer != claimer, "Old and new claimer is same");
        require(_claimData[oldClaimer].claimAmount > 0, "Old claimer not found");
        require(_claimData[claimer].claimAmount == 0, "New claimer already set");
        _claimData[claimer] = _claimData[oldClaimer];
        delete _claimData[oldClaimer];
    }
}