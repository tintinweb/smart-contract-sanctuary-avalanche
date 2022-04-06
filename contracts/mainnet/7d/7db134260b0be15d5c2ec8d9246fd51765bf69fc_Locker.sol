/**
 *Submitted for verification at snowtrace.io on 2022-04-05
*/

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
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

pragma solidity ^0.8.0;

contract Locker is Ownable {
    // a time + amount pool
    struct TimeAmount {
        uint256 time;
        uint256 amount;
    }

    // the token to lock
    IERC20 public token;

    // the pools
    TimeAmount[] public timeAmounts;

    // the balance of each address in each pool
    mapping (uint256 => mapping (address => uint256)) public balanceOf;

    // total supply in each pool
    mapping (uint256 => uint256) public totalSupply;

    // locker is open for new lockings
    bool public isLocking = true;

    modifier requireIsLocking {
      require(isLocking, 'locker: locking closed');
      _;
    }

    event Lock(address indexed _address, uint256 indexed _timeAmountIndex, uint256 _amount);
    event Unlock(address indexed _address, uint256 indexed _timeAmountIndex, uint256 _amount);

    constructor(IERC20 _token, TimeAmount[] memory _timeAmounts) {
        token = _token;
        uint256 i = 0;
        while (i < _timeAmounts.length) {
            timeAmounts.push(_timeAmounts[i++]);
        }
    }

    // edit pool
    function setTimeAmount(uint256 _timeAmountIndex, TimeAmount memory _timeAmounts) public onlyOwner {
        timeAmounts[_timeAmountIndex] = _timeAmounts;
    }

    // add pool
    function addTimeAmount(TimeAmount memory _timeAmounts) public onlyOwner {
        timeAmounts.push(_timeAmounts);
    }

    // close depositing
    function setIsLocking(bool _isLocking) public onlyOwner {
        isLocking = _isLocking;
    }

    // if someone sends wrong tokens to this contract, owner can send them back
    function recoverWrongTokensSentToContract(IERC20 _token, address _address, uint256 _balance) public onlyOwner {
        _token.transfer(_address, _balance);
    }

    // migrate from a previous locker
    function migrateFrom(address[] memory _addresses, uint256[] memory _timeAmountIndexes, uint256[] memory _amounts) public onlyOwner {
        uint256 i = 0;
        while (i < _addresses.length) {
            balanceOf[_timeAmountIndexes[i]][_addresses[i]] += _amounts[i];
            emit Lock(_addresses[i], _timeAmountIndexes[i], _amounts[i]);
            totalSupply[_timeAmountIndexes[i]] += _amounts[i];
            i++;
        }
    }

    function lock(uint256 _timeAmountIndex, uint256 _amount) public requireIsLocking {
        require(_timeAmountIndex < timeAmounts.length, 'locker: _timeAmountIndex does not exist');
        TimeAmount memory timeAmount = timeAmounts[_timeAmountIndex];
        require(_amount >= timeAmount.amount, 'locker: _amount smaller than timeAmount.amount');

        // transfer the token
        token.transferFrom(msg.sender, address(this), _amount);
        balanceOf[_timeAmountIndex][msg.sender] += _amount;
        emit Lock(msg.sender, _timeAmountIndex, _amount);

        // update total supply
        totalSupply[_timeAmountIndex] += _amount;
    }

    // lock without approving
    function lockWithPermit(uint256 _timeAmountIndex, uint256 _amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        token.permit(address(msg.sender), address(this), _amount, deadline, v, r, s);
        lock(_timeAmountIndex, _amount);
    }

    function unlock(uint256 _timeAmountIndex) public {
        require(_timeAmountIndex < timeAmounts.length, 'locker: _timeAmountIndex does not exist');
        uint256 balance = balanceOf[_timeAmountIndex][msg.sender];
        require(balance > 0, 'locker: _timeAmountIndex balance is 0');
        TimeAmount memory timeAmount = timeAmounts[_timeAmountIndex];
        require(block.timestamp > timeAmount.time, 'locker: lock time not elapsed');

        // transfer the token
        balanceOf[_timeAmountIndex][msg.sender] = 0;
        token.transfer(msg.sender, balance);
        emit Unlock(msg.sender, _timeAmountIndex, balance);

        // update total supply
        totalSupply[_timeAmountIndex] -= balance;
    }

    // how much time left until a pool unlocks
    function timeLeft(uint256 _timeAmountIndex) public view returns (uint256) {
        require(_timeAmountIndex < timeAmounts.length, 'locker: _timeAmountIndex does not exist');
        if (block.timestamp > timeAmounts[_timeAmountIndex].time) {
            return 0;
        }
        return timeAmounts[_timeAmountIndex].time - block.timestamp;
    }

    function timeAmountCount() public view returns (uint256) {
        return timeAmounts.length;
    }
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}