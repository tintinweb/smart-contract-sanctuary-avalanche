/**
 *Submitted for verification at snowtrace.io on 2022-09-04
*/

/**
    #TORTUGA
    #TORTUGA COIN features
    For each TRX : 
    1% treasure distributed to one of the standard Tortuga holders
    3% reflected to all standard holders 
    3% burn forever sent to dead address, excluded from reflect and treasure
   
    This smart contract is a fork from the audited Safemoon but we fixed all the issues and possible rugpull mentioned here and on internet.
        https://bscscan.com/address/0x8076C74C5e3F5852037F31Ff0093Eeb8c8ADd8D3#code
    Issues fixed : SSL-01, 02, 03, 05, 09, 10, 11, 12 (view CertiK audit here : https://www.certik.org/projects/safemoon)
    We removed all the possible rugpull.
    We decided to BURN instead of the LIQUIDITY FEATURE as it was more and more criticized because of : 
    - The major rugpull risk : LP Tokens retrieved from the automatic lopsided “addliquidity” events are transferred to the SafeMoon Contract 
    Owner who currently holds a huge amount of token and is able to be withdrawn from the Liquidity Pool.
    - The negative effect on token price : The automatic swapAndLiquify event devalues the token in relation to BNB and all other currencies
    because the source of the deposited BNB was the Liquidity Pool itself.
    - SSL-06, 07, 08.
    
    New functions added:
        - New tax created as tresorFee, the treasure of the Tortuga pirates. 
        - taxFee, burnFee and tresorFee have a MAX VALUE so NO RUGPULL can happen : 3%, 3% and 2% (we let the possibity to increase the 
        tresorFee from 1% to 2% for periods of high rewards.
        - Function _distributeTresor will pick one of the standard holders (not owner, not contract, not burn address ...)
          and distribute the tax to him. In the "else" case it will be sent to the contract address.
        - If the contract address hold tokens, they will be used for airdrop, burn or rewards. 
        - Two "ANTI-WHALE" mechanisms : max trx amount is 1% of the original total supply
                                        max wallet balance is 5% of the total supply
        - Smart-contract has been adapted for Avalanche and Pangolin deployment.
    
    Learn more about our quest on :
    tortugacoin.quest
   
    SPDX-License-Identifier: MIT
*/

pragma solidity ^0.7.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
     *
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
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IJoeRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);
}

contract TortugaCoin is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) public _tresorOwned;
    mapping (address => uint256) public _nbSelected;
    mapping (address => uint256) private index;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    
    address[] private _excluded;
    address[] private holders; 
    
    address private burnAddress = 0x0000000000000000000000000000000000000001;
    address private rewardAddress = 0x5B45553B6f8C72054A418AF1ee5Ea52B3DD5c74A;
    
    uint private nonce = 0;
    
    uint256 public _taxFee = 3;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _burnFee = 3;
    uint256 private _previousBurnFee = _burnFee;
    
    uint256 public _tresorFee = 1;
    uint256 private _previousTresorFee = _tresorFee;
    
    //number of holders sharing the tresor fee for each trx
    uint256 public _nbWinners = 1;
    
    //min of Tortuga to owned to be eligible for the tresor
    uint256 public _minTortuga = 1* 10**6 * 10**9;
    
    uint256 public _tTresorTotal;
    
    uint256 private constant _maxTxAmount = _tTotal / 100; // 1% of the total supply
    
    uint256 private constant maxWalletBalance = _tTotal / 20; // 5% of the total supply
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1 * 10**12 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    string private _name = 'TortugaCoin';
    string private _symbol = 'TORTUGA';
    uint8 private _decimals = 9;
    
    IJoeRouter public immutable joeRouter;
    address public immutable joePair;
    
    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        
        // main net router
        IJoeRouter _joeRouter = IJoeRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);

        // Create a pangolin pair for this new token
        joePair = IJoeFactory(_joeRouter.factory())
            .createPair(address(this), _joeRouter.WAVAX());

        // set the rest of the contract variables
        joeRouter = _joeRouter;
        
        // exclude owner, this contract and charity from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[burnAddress] = true;
        
        // exclude the owner and this contract from rewards
	    excludeFromReward(owner());	
        excludeFromReward(address(this));
        excludeFromReward(burnAddress);
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    
    function setTresorFeePercent(uint256 tresorFee) external onlyOwner() {
        //max 2%
        if ( tresorFee < 3){
            _tresorFee = tresorFee;
        }
    }
    
    function setBurnFeePercent(uint256 burnFee) external onlyOwner() {
        //max 3%
        if ( burnFee < 4){
            _burnFee = burnFee;
        }
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        //max 3%
        if ( taxFee < 4){
            _taxFee = taxFee;
        }
    }
    
    function setNbWinners(uint256 nbWinners) external onlyOwner() {
        if ( nbWinners < holders.length + 2 && nbWinners!= 0){
            _nbWinners = nbWinners;
        }
    }
    
    function setMinTortuga(uint256 minTortuga) external onlyOwner() {
            _minTortuga = minTortuga;
    }
    
    function excludeFromReward(address account) public onlyOwner() {	
        require(!_isExcluded[account], "Account is already excluded");	
        if(_rOwned[account] > 0) {	
            _tOwned[account] = tokenFromReflection(_rOwned[account]);	
        }	
        _isExcluded[account] = true;	
        _excluded.push(account);	
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _burnFee = _previousBurnFee;
        _tresorFee = _previousTresorFee;
    }
    
    function removeAllFee() private {
        if(_taxFee == 0 && _burnFee == 0 && _tresorFee == 0) return;
        
        _previousTresorFee = _tresorFee;
        _previousTaxFee = _taxFee;
        _previousBurnFee = _burnFee;
        
        _taxFee = 0;
        _burnFee = 0;
        _tresorFee = 0;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _tokenBurn(uint256 tBurn) private {	
		_tOwned[burnAddress] = _tOwned[burnAddress].add(tBurn);
	}
	
	function getNumber() internal returns (uint) {
        uint256 number = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % holders.length;
        nonce++;
        return number;
    }
    
    function _distributeTresor(uint256 tTresor) private {
        uint256 currentRate =  _getRate();
        uint256 rTresor = tTresor.mul(currentRate);
        rTresor = rTresor.div(_nbWinners);
        tTresor = tTresor.div(_nbWinners);
        for (uint i=0; i<_nbWinners; i++) {
            uint256 number = getNumber();
            if (!_isExcluded[holders[number]] && balanceOf(holders[number]) > _minTortuga && holders[number] != joePair){
                _tresorOwned[holders[number]] = _tresorOwned[holders[number]].add(tTresor);
                _rOwned[holders[number]] = _rOwned[holders[number]].add(rTresor);
                _nbSelected[holders[number]] += 1;
                _tTresorTotal.add(tTresor);
            } else {
                _tresorOwned[rewardAddress] = _tresorOwned[rewardAddress].add(tTresor);
                _rOwned[rewardAddress] = _rOwned[rewardAddress].add(rTresor);
                _nbSelected[rewardAddress] += 1;
                _tTresorTotal.add(tTresor);
            }
        }
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if (balanceOf(to) + amount >= _minTortuga && index[to] == 0 && to != burnAddress) { 
            index[to] = holders.length + 1; 
            holders.push(to);
        }
        if ( balanceOf(from) - amount < _minTortuga && index[from] != 0){
            index[holders[holders.length - 1]] = index[from];
            holders[index[from] - 1] = holders[holders.length - 1];
            index[from] = 0;
            holders.pop();
        }
        
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            
        if ( maxWalletBalance > 0 && !isExcludedFromFee(from) && !isExcludedFromFee(to) && to != joePair){
            uint256 recipientBalance = balanceOf(to);
            require(recipientBalance + amount <= maxWalletBalance, "New balance would exceed the maxWalletBalance");
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        if(!takeFee)
            removeAllFee();
        
        if (_isExcluded[from] && !_isExcluded[to]) {
            _transferFromExcluded(from, to, amount);
        } else if (!_isExcluded[from] && _isExcluded[to]) {
            _transferToExcluded(from, to, amount);
        } else if (!_isExcluded[from] && !_isExcluded[to]) {
            _transferStandard(from, to, amount);
        } else if (_isExcluded[from] && _isExcluded[to]) {
            _transferBothExcluded(from, to, amount);
        } else {
            _transferStandard(from, to, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tBurn, uint256 tTresor) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _tokenBurn(tBurn);
        _distributeTresor(tTresor);
        _reflectFee(rFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tBurn, uint256 tTresor) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _tokenBurn(tBurn);
        _distributeTresor(tTresor);
        _reflectFee(rFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tBurn, uint256 tTresor) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _tokenBurn(tBurn);
        _distributeTresor(tTresor);
        _reflectFee(rFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tBurn, uint256 tTresor) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _tokenBurn(tBurn);
        _distributeTresor(tTresor);
        _reflectFee(rFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee) private {
        _rTotal = _rTotal.sub(rFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tTresor) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tBurn, tTresor, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tBurn, tTresor);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(_taxFee).div(10**2);
        uint256 tBurn = tAmount.mul(_burnFee).div(10**2);
        uint256 tTresor = tAmount.mul(_tresorFee).div(10**2);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tBurn).sub(tTresor);
        return (tTransferAmount, tFee, tBurn, tTresor);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tBurn, uint256 tTresor, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rTresor = tTresor.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rBurn).sub(rTresor);
        return (rAmount, rTransferAmount, rFee);
    }


    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
}