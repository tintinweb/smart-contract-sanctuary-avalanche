/**
 *Submitted for verification at testnet.snowtrace.io on 2023-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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



contract SegMintReferral is Ownable {
    struct ReferralData {
        string referralId;
        uint referralCount;
        address[] referredTo;
    }

    IERC20 private _SGLT;

    mapping (address => bool) private _hasUserCreatedReferralId;
    mapping (address => ReferralData) private _referralData;
    mapping(string=>bool) private idRegistered;
    mapping(address=>bool) private bonusTransferred;
    address[] private _tempArray;
    uint256 private referralBonus;

    event SGLTSet(address indexed previousSGLT, address indexed newSGLT);
    event ReferralBonusSet(uint256 indexed previousReferralBonus, uint256 indexed newReferralBonus);

    function getSGTL() external view returns (address) {
        return address(_SGLT);
    }

    function setSGTL(address sgtlAddress) external onlyOwner {
        require(sgtlAddress != address(0), "Cannot set zero address");
        _SGLT = IERC20(sgtlAddress);
        emit SGLTSet(address(_SGLT), sgtlAddress);
    }

    function getReferralBonus() external view returns (uint256) {
        return referralBonus;
    }

    function setReferralBonus(uint256 ReferralBonus_) external onlyOwner {
        uint256 previousReferralBonus = referralBonus;
        referralBonus = ReferralBonus_;
        emit ReferralBonusSet(previousReferralBonus, referralBonus);
    }

    function getToken() external view returns (address) {
        return address(_SGLT);
    }

    function hasUserCreatedReferralId(address account) external view returns (bool) {
        return _hasUserCreatedReferralId[account];
    }

    function getReferralData(address account) external view returns (ReferralData memory) {
        return _referralData[account];
    }

    function getIdRegistered(string memory id) public view returns (bool) {
        return idRegistered[id];
    }

    function createReferralId(string memory id) external {
        require(msg.sender != address(0), "Cannot call from zero address");
        require(!_hasUserCreatedReferralId[msg.sender], "You have already created a referral id");
        require(!getIdRegistered(toLowerCase(id)), "Id Already Registered");
        idRegistered[toLowerCase(id)] = true;
        _hasUserCreatedReferralId[msg.sender] = true;
        ReferralData memory newReferralData = ReferralData(id, 0, _tempArray);
        _referralData[msg.sender] = newReferralData;
    }

    
    function toLowerCase(string memory input) public pure returns (string memory) {
        bytes memory inputBytes = bytes(input);
        bytes memory result = new bytes(inputBytes.length);
        
        for (uint256 i = 0; i < inputBytes.length; i++) {
            if (inputBytes[i] >= 0x41 && inputBytes[i] <= 0x5A) { // A-Z
                result[i] = bytes1(uint8(inputBytes[i]) + 32);
            } else {
                result[i] = inputBytes[i];
            }
        }
        
        return string(result);
    }

    function sendTokens(address[] memory to, address[] memory from) external onlyOwner {
        require(_hasUserCreatedReferralId[msg.sender], "You not already created a referral id");
        for (uint i = 0; i < to.length; i ++) {
            joinReferral(to[i], from[i]);
        }
    }

    function joinReferral(address referrance, address referrer) internal {
        if(!bonusTransferred[referrance]){
            _referralData[referrer].referralCount += 1;
            _referralData[referrer].referredTo.push(referrance);
            _SGLT.transfer(referrer, referralBonus);
        }
    }
}