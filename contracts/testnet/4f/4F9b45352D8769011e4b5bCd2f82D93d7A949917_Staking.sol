// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

pragma solidity ^0.8.11;
// SPDX-License-Identifier: MIT
import '@openzeppelin/contracts/access/Ownable.sol';

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract Staking is Ownable {
    IERC20 public TKN;

    uint256[5] public periods = [30 days, 60 days, 90 days, 180 days, 360 days];
    uint32[5] public rates = [10000, 12500, 15000, 17500, 20000];
    uint256 public rewardsPool;
    uint256 public MAX_STAKES = 100;

    struct Stake {
        uint8 class;
        uint256 initialAmount;
        uint256 finalAmount;
        uint256 timestamp;
        bool unstaked;
    }

    Stake[] public stakes;
    mapping(address => uint256[]) public stakesOf;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => uint256) public totalValueLocked;

    event Staked(
        address indexed sender,
        uint8 indexed class,
        uint256 amount,
        uint256 finalAmount
    );
    event Unstaked(address indexed sender, uint8 indexed class, uint256 amount);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);
    event IncreaseRewardsPool(address indexed adder, uint256 added, uint256 newSize);

    constructor(IERC20 _TKN) {
        TKN = _TKN;
        totalValueLocked[0] = 0;
        totalValueLocked[1] = 0;
        totalValueLocked[2] = 0;
        totalValueLocked[3] = 0;
        totalValueLocked[4] = 0;
    }

    /// @dev Shows needed range stakes info
    /// @param _from range starts from this
    /// @param _to range ends on this
    /// @return s returns info array of stakes in selected range
    function stakesInfo(uint256 _from, uint256 _to)
        external
        view
        returns (Stake[] memory s)
    {
        s = new Stake[](_to - _from);
        for (uint256 i = _from; i < _to; i++) s[i - _from] = stakes[i];
    }

    /// @dev Shows all stakes info
    /// @return s returns info array of all stakes
    function stakesInfoAll() external view returns (Stake[] memory s) {
        s = new Stake[](stakes.length);
        for (uint256 i = 0; i < stakes.length; i++) s[i] = stakes[i];
    }

    /// @dev Shows all stakes amount on this contract
    /// @return length of stakes array
    function stakesLength() external view returns (uint256) {
        return stakes.length;
    }

    /// @dev Shows all stakes info of selected user
    /// @param _me selected user
    /// @return s stakes info of selected user
    /// @return indexes user can see pool ids to interract with contract
    function myStakes(address _me)
        external
        view
        returns (Stake[] memory s, uint256[] memory indexes)
    {
        s = new Stake[](stakesOf[_me].length);
        indexes = new uint256[](stakesOf[_me].length);
        for (uint256 i = 0; i < stakesOf[_me].length; i++) {
            indexes[i] = stakesOf[_me][i];
            s[i] = stakes[indexes[i]];
        }
    }

    /// @dev Shows staking pools amount
    /// @param _me selected user
    /// @return l amount of stakes
    function myActiveStakesCount(address _me) public view returns (uint256 l) {
        uint256[] storage _s = stakesOf[_me];
        for (uint256 i = 0; i < _s.length; i++) if (!stakes[_s[i]].unstaked) l++;
    }

    /// @dev Recieves token and sets staking info
    /// @param _class corresponds to staking period
    /// @param _amount staking amount
    function stake(uint8 _class, uint256 _amount) external {
        require(_class < 5, 'Wrong class'); // data valid
        require(myActiveStakesCount(msg.sender) < MAX_STAKES, 'MAX_STAKES overflow'); // has space for new active stake
        uint256 _finalAmount = _amount +
            ((_amount * rates[_class] * periods[_class]) / 1 days) /
            10000 /
            360;
        require(rewardsPool >= _finalAmount - _amount, 'Rewards pool is empty for now');
        rewardsPool -= _finalAmount - _amount;
        TKN.transferFrom(msg.sender, address(this), _amount);
        uint256 _index = stakes.length;
        stakesOf[msg.sender].push(_index);
        stakes.push(
            Stake({
                class: _class,
                initialAmount: _amount,
                finalAmount: _finalAmount,
                timestamp: block.timestamp,
                unstaked: false
            })
        );
        totalValueLocked[_class] += _amount;
        ownerOf[_index] = msg.sender;
        emit Staked(msg.sender, _class, _amount, _finalAmount);
    }

    /// @dev Pays rewards to user and transfers staked tokens
    /// @param _index index of user's staking pool
    function unstake(uint256 _index) public {
        require(msg.sender == ownerOf[_index], 'Not correct index');
        Stake storage _s = stakes[_index];
        require(!_s.unstaked, 'Already unstaked'); // not unstaked yet
        require(
            block.timestamp >= _s.timestamp + periods[_s.class],
            'Staking period not finished'
        ); // staking period finished
        TKN.transfer(msg.sender, _s.finalAmount);
        _s.unstaked = true;
        totalValueLocked[_s.class] -= _s.initialAmount;
        emit Unstaked(msg.sender, _s.class, _s.finalAmount);
    }

    /// @dev Returns to owner accidentally sent to this contract not staking tokens
    /// @param _TKN token to be returned
    function returnAccidentallySent(IERC20 _TKN) public onlyOwner {
        require(address(_TKN) != address(TKN), 'Unable to withdraw staking token');
        uint256 _amount = _TKN.balanceOf(address(this));
        _TKN.transfer(msg.sender, _amount);
    }

    /// @dev Receives staking tokens for paying reewards
    /// @param _amount amount of tokens to receive
    function increaseRewardsPool(uint256 _amount) public {
        TKN.transferFrom(msg.sender, address(this), _amount);
        rewardsPool += _amount;
        emit IncreaseRewardsPool(msg.sender, _amount, rewardsPool);
    }

    /// @dev Changes max staking pools amount for one user
    /// @param _max new max pools amount
    function updateMax(uint256 _max) public onlyOwner {
        MAX_STAKES = _max;
    }

    /// @dev Show staking classes amount
    /// @return classes amount
    function getClassesAmount() external view returns (uint256) {
        return periods.length;
    }

    /// @dev Changes apy rates
    /// @param newRates is array of new rates
    function setRates(uint32[5] memory newRates) external onlyOwner {
        rates = newRates;
    }
}