/**
 *Submitted for verification at snowtrace.io on 2022-03-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IManagement {

    function getNodeLimit() external view returns(uint256);

    function getClaimInterval() external view returns(uint256);

    function getTotalCount() external view returns(uint256);

    function getNodesCountOfUser(address account) external view returns(uint256);

    function createNode(address account, string memory _name, uint256 _rewardPerMinute) external;

    function airdropNode(address account, string memory _name, uint256 _rewardPerMinute) external;

    function calculateAvailableReward(address account) external view returns(uint256);

    function calculateAvailableReward(address account, uint256 _index) external view returns(uint256);

    function cashoutAllReward(address account) external returns(uint256);

    function cashoutReward(address account, uint256 _index) external returns(uint256);

    function compoundNode(address account, uint256 amount) external returns(uint256);

    function getNodeNames(address account) external view returns (string memory);

    function getNodeCreateTime(address account) external view returns (string memory);

    function getNodeLastClaimTime(address account) external view returns (string memory);

    function getNoderewardPerDay(address account) external view returns (string memory);

    function getNodeAvailableReward(address account) external view returns (string memory);
}

library SafeMath {
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
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
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
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
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
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
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
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
   
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

   
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

contract Presale is Context, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct Contributor {
        uint256 investAmount;
        uint256 claimableAmount;
        uint256 baseAmount;
    }

    mapping(address => bool) public whitelist;
    mapping (address => Contributor) public _contributions;
    mapping (address => bool) public isContributor;

    uint256 public _rewardPerDay = 335 * 1e15; // ok

    IManagement public _management; // ok

    IERC20 public _presaleToken; // ok
    uint256 public _presaleTokenDecimals; // ok

    IERC20 public _investToken; // ok
    uint256 public _investTokenDecimals; // ok

    address public _burnAddress = 0x000000000000000000000000000000000000dEaD; // ok
    address public _treasury; // ok

    uint256 public _hardCap = 500 * 1000 * 1e18; // ok
    uint256 public _softCap = 100 * 1000 * 1e18; // ok

    uint256 public _endICOTime; // ok

    uint256 public _minPurchase = 0; // ok
    uint256 public _maxPurchase = 500 * 1e18; // ok

    bool public icoStatus = false; // ok
    uint256 public _investedAmount = 0; // ok
    uint256 public _accumulatedAmount = 0; // ok

    bool public _reclaimable = false; // ok

    modifier icoActive() {
        require(_endICOTime > 0 && block.timestamp < _endICOTime && icoStatus, "ICO must be active");
        _;
    }
    
    modifier icoNotActive() {
        require(_endICOTime < block.timestamp && !icoStatus, "ICO should not be active");
        _;
    }

    constructor () {
    }

    function addWhitelist(address _address) external onlyOwner {
        whitelist[_address] = true;
    }

    function addMultipleWhitelist(address[] calldata _addresses) external onlyOwner {
        require(_addresses.length <= 5000, "jesus, too many addresses");
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;  
        }
    }

    //Start Pre-Sale
    function startICO(
        address management,
        address _opec,
        uint256 _opecDecimal,
        address _invest,
        uint256 _investDecimal,
        address treasury
    ) external onlyOwner icoNotActive() {
        icoStatus = true;

        _management = IManagement(management);

        _presaleToken = IERC20(_opec);
        _presaleTokenDecimals = _opecDecimal;

        _investToken = IERC20(_invest);
        _investTokenDecimals = _investDecimal;

        _treasury = treasury;

        _endICOTime = block.timestamp + 3 days;
    }

    function toggleICO() external onlyOwner(){
        icoStatus = !icoStatus;

        if (_investedAmount < _softCap) {
            _reclaimable = true;
        }
    }

    function buyTokens(uint256 _invest) public nonReentrant icoActive {
        require(address(msg.sender) != address(0), "PRESALE: SENDER IS ZERO ADDRESS");
        require(_invest >=1 && _invest <= 5, "PRESALE: INVALID INVEST TYPE");
        require(_investedAmount + _invest * 100e18 <= _hardCap, "PRESALE: INVEST AMOUNT REACHED HARDCAP");
        require(_invest * 100e18 >= _minPurchase && _invest * 100e18 <= _maxPurchase, "PRESALE: MAX/MIN LIMIT ERROR");
        require(_investToken.balanceOf(msg.sender) >= _invest * 100e18, "PRESALE: INVEST BALANCE ERROR");
        require(!isContributor[msg.sender], "PRESALE: HAVE ALREADY PURCHASED TOKEN");
        require(whitelist[msg.sender], "PRESALE: INVESTOR NOT WHITELIST");

        uint256 baseAmount = calculateAmount(_invest);

        require(_accumulatedAmount + baseAmount * 10e18 <= _presaleToken.balanceOf(address(this)), "PRESALE: INSUFFICIENT BALANCE");
 
        _contributions[msg.sender] = Contributor({
            investAmount: _invest * 100e18,
            claimableAmount: baseAmount * 10e18,
            baseAmount: baseAmount
        });

        _investToken.transferFrom(msg.sender, address(this), _invest * 100e18);

        isContributor[msg.sender] = true;

        _investedAmount += _invest * 100e18;
        _accumulatedAmount += baseAmount * 10e18;
    }

    function calculateAmount(uint256 _invest) internal pure returns(uint256) {
        return _invest * 2;
    }

    function claimTokens() public nonReentrant icoNotActive {
        require(!_reclaimable, "PRESALE: CLAIM ERROR");
        require(address(msg.sender) != address(0), "PRESALE: SENDER IS ZERO ADDRESS");
        require(isContributor[msg.sender] == true, "PRESALE: CLAIM NO CONTRIBUTOR");

        isContributor[msg.sender] = false;

        uint256 amount = _contributions[msg.sender].claimableAmount;
        require(amount > 0, "PRESALE: CLAIM AMOUNT ERROR");

        _presaleToken.transfer(address(msg.sender), amount);

        for (uint256 i = 0; i < _contributions[msg.sender].baseAmount; i ++) {
            _management.airdropNode(msg.sender, "Presale Airdrop Node", _rewardPerDay);
        }
    }

    function reclaimInvest() public nonReentrant icoNotActive {
        require(_reclaimable, "PRESALE: RECLAIM INVEST ERROR");
        require(address(msg.sender) != address(0), "PRESALE: SENDER IS ZERO ADDRESS");
        require(isContributor[msg.sender] == true, "PRESALE: CLAIM NO CONTRIBUTOR");

        uint256 amount = _contributions[msg.sender].investAmount;
        require(amount > 0, "PRESALE: RECLAIM AMOUNT ERROR");

        _investToken.transfer(msg.sender, amount);
    }

    function withdraw() public onlyOwner icoNotActive {
        require(!_reclaimable, "PRESALE: WITHDRAW ERROR");
        uint256 totalInvestAmount = _investToken.balanceOf(address(this));
        uint256 remainPresaleAmount = _presaleToken.balanceOf(address(this));

        require(totalInvestAmount > 0, "PRESALE: RECLAIM AMOUNT ERROR");

        _investToken.transfer(_treasury, totalInvestAmount);
        _presaleToken.transfer(_burnAddress, remainPresaleAmount);
    }

    function getBaseAmount(address account) external returns (uint256) {
        require(isContributor[account], "NOT CONTRIBUTOR");
        return _contributions[account].baseAmount;
    }
}