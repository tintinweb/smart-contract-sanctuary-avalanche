// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IRebaseToken.sol";

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(isOwner(),"Vault: Not Owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract Vault is Ownable{ 

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address private _walletTaxCollector;
    address private _rebaseTokenContract;

    /* ========== CONSTRUCTOR ============= */

    constructor(address walletTaxeCollector, address rebaseTokenContract){
        _walletTaxCollector = walletTaxeCollector;
        _rebaseTokenContract = rebaseTokenContract;
        rebaseToken = IRebaseToken(_rebaseTokenContract);
    }
    

    /* ========== DATA STRUCTURES ========== */

    struct UserInfo {
        uint256 withdrawTime; // Time when the user will be able to withdraw w/o taxes
        uint256 amountStaked;
    }

    struct VaultInfo {
        bool isInitialized; // if Vault is initialized
        bool isOpened; // To prevent new comers after a shutdown of the vault
        uint256 lockDuration; // How long a user has to wait to withdraw without taxes (seconds)
        uint256 additionnalReward; // The additionnal percentage of reward the user will receive
        uint256 taxesPerEpoch; // How much the user will be taxed for each epoch of early withdraw
        uint256 classicYieldOnDuration; // How much would a user have without staking in the vault
    }
    /* ========== STATE VARIABLES ========== */
    
  
    IRebaseToken public rebaseToken;

    VaultInfo[] public vaultInfo;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo; // The number of the vault gives the info for each user in this vault



    /* ========== EVENTS ========== */

    event Initialized(address indexed executor, uint256 at, uint256 vaultNumber);
    event Staked(address indexed user, uint256 amount, uint256 vaultNumber);
    event Withdrawn(address indexed user, uint256 amount, uint256 vaultNumber);
    event RewardPaid(address indexed user, uint256 reward, uint256 vaultNumber);
    event RewardAdded(address indexed user, uint256 reward, uint256 vaultNumber);


    /* ========== GOVERNANCE ========== */




    function add(
        uint256 _lockDuration, 
        uint256 _additionnalReward,
        uint256 _taxesPerEpoch //must be given *1000
    ) public onlyOwner {
        
        require(_taxesPerEpoch>0,"Vault: TaxesPerEpoch must be positive");//changer max 
        require(_lockDuration>0,"Vault: LockDuration must be positive");
        require(_additionnalReward>0, "Additionnal reward must be positive");
        require((_lockDuration/14400)*_taxesPerEpoch.div(1000) < 30,"Vault: taxes not < 30");

        vaultInfo.push(VaultInfo({
            isInitialized : false,
            isOpened : true,
            lockDuration : _lockDuration,
            additionnalReward : _additionnalReward,
            taxesPerEpoch : _taxesPerEpoch,
            classicYieldOnDuration : (1+(rebaseToken.getRewardYield()/rebaseToken.getRewardYieldDenominator())**(_lockDuration/14400))
            }));

        
    }


    /* ========== SETTERS ========== */

    function setInitialize(uint256 vaultNumber, bool _init) external onlyOwner {
        require(vaultNumber<vaultInfo.length, "Vault: Doesn't exist");
       
        vaultInfo[vaultNumber].isInitialized = _init;
    }
    function setOpened(uint256 vaultNumber, bool _open) external onlyOwner {
                require(vaultNumber<vaultInfo.length, "Vault: Doesn't exist");

         require(vaultInfo[vaultNumber].isInitialized, "Vault: not initialized yet");
        vaultInfo[vaultNumber].isOpened = _open;
    }
    function setLockDuration(uint256 vaultNumber, uint256 nbEpoch) external onlyOwner {
                        require(vaultNumber<vaultInfo.length, "Vault: Doesn't exist");

        vaultInfo[vaultNumber].lockDuration = nbEpoch*14400;
    }
    function setAdditionnalReward(uint256 vaultNumber, uint256 _add) external onlyOwner {
                        require(vaultNumber<vaultInfo.length, "Vault: Doesn't exist");

        vaultInfo[vaultNumber].additionnalReward = _add;
    }
    function setTaxesPerEpoch(uint256 vaultNumber, uint256 _taxes) external onlyOwner {
                        require(vaultNumber<vaultInfo.length, "Vault: Doesn't exist");

        vaultInfo[vaultNumber].taxesPerEpoch = _taxes;
    }
    /* ========== GETTERS ========= */
    
    function getInitialize(uint256 vaultNumber) external view returns(bool) {
        return vaultInfo[vaultNumber].isInitialized;
    }
    function getOpened(uint256 vaultNumber) external view returns(bool) {
        return vaultInfo[vaultNumber].isOpened;
    }
    function getLockDuration(uint256 vaultNumber) external view returns(uint256){
        return (vaultInfo[vaultNumber].lockDuration);
    }
    function getAdditionnalReward(uint256 vaultNumber) external view returns(uint256){
        return vaultInfo[vaultNumber].additionnalReward;
    }
    function getTaxesPerEpoch(uint256 vaultNumber) external view returns(uint256) {
        return vaultInfo[vaultNumber].taxesPerEpoch;
    }
    function getAmountStaked(uint256 vaultNumber, address user) external view returns(uint256){
        return userInfo[vaultNumber][user].amountStaked;
    }
    function getWithdrawTime(uint256 vaultNumber, address user) external view returns(uint256){
        return userInfo[vaultNumber][user].withdrawTime;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount, uint256 vaultNumber) public {
        require(vaultNumber<vaultInfo.length, "Vault: Doesn't exist");
        require(vaultInfo[vaultNumber].isInitialized, "Vault: not initialized yet");
        require(vaultInfo[vaultNumber].isOpened, "Vault: not opened yet");
        require(amount > 0, "Vault: Cannot stake 0");
        require(userInfo[vaultNumber][msg.sender].amountStaked == 0, "Vault: you can't stake until the end of your previous lock");

        
        userInfo[vaultNumber][msg.sender].withdrawTime = block.timestamp.add(vaultInfo[vaultNumber].lockDuration); // Reset the withdraw time
        

        rebaseToken.burnFrom(msg.sender, amount); //Burn the amount that is staked (all the withdraw will be minted on time)

        userInfo[vaultNumber][msg.sender].amountStaked = amount; // Add the new amount to the total already staked;

        emit Staked(msg.sender, amount, vaultNumber); 

    }

    function withdraw(uint256 vaultNumber) public { //A chaque fois verifier que le vault existe et est applicable

        require(vaultNumber<vaultInfo.length, "Vault: Doesn't exist");
        require(vaultInfo[vaultNumber].isInitialized, "Vault: not initialized yet");
        require(userInfo[vaultNumber][msg.sender].amountStaked>0,"Vault: You don't have money in this vault"); //Vérifier

        uint256 toWithdraw = userInfo[vaultNumber][msg.sender].amountStaked; //Store data before putting it to 0
        uint256 _withdrawTime = (userInfo[vaultNumber][msg.sender].withdrawTime);
        
        userInfo[vaultNumber][msg.sender].amountStaked = 0; //Reset amount staked by the user in this vault
        
        if(_withdrawTime > block.timestamp){     
            uint256 numberOfEpochEarly = (_withdrawTime.sub(block.timestamp)).div(14400);
            uint256 taxed = toWithdraw.mul(numberOfEpochEarly.mul(vaultInfo[vaultNumber].taxesPerEpoch.div(100000)));
            uint256 returnWithTaxes = toWithdraw.sub(taxed); //calcul
            rebaseToken.mint(msg.sender,returnWithTaxes);
            rebaseToken.mint(_walletTaxCollector,taxed);
        }   

        else{
             uint256 reward = toWithdraw.mul(vaultInfo[vaultNumber].classicYieldOnDuration.mul(100)).mul(uint256(1).add(vaultInfo[vaultNumber].additionnalReward.div(100))); // Calculate how much to send to user //Ajouter l'apy du titano
             if (reward > 0) {
                 rebaseToken.mint(_walletTaxCollector,reward);
                 emit RewardPaid(msg.sender, reward, vaultNumber);
             }
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRebaseToken {
  function MAX_FEE_BUY (  ) external view returns ( uint256 );
  function MAX_FEE_RATE (  ) external view returns ( uint256 );
  function MAX_FEE_SELL (  ) external view returns ( uint256 );
  function _markerPairs ( uint256 ) external view returns ( address );
  function addMinter(address) external;
  function allowance ( address owner_, address spender ) external view returns ( uint256 );
  function approve ( address spender, uint256 value ) external returns ( bool );
  function autoRebase (  ) external view returns ( bool );
  function automatedMarketMakerPairs ( address ) external view returns ( bool );
  function balanceOf ( address who ) external view returns ( uint256 );
  function burn(uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
  function buyFeeRFV (  ) external view returns ( uint256 );
  function checkFeeExempt ( address _addr ) external view returns ( bool );
  function checkSwapThreshold (  ) external view returns ( uint256 );
  function clearStuckBalance ( address _receiver ) external;
  function decimals (  ) external view returns ( uint8 );
  function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
  function feeDenominator (  ) external view returns ( uint256 );
  function getCirculatingSupply (  ) external view returns ( uint256 );
  function getLiquidityBacking ( uint256 accuracy ) external view returns ( uint256 );
  function getRewardYield (  ) external view returns (uint256);
  function getRewardYieldDenominator (  ) external view returns (uint256);
  function increaseAllowance ( address spender, uint256 addedValue ) external returns ( bool );
  function initialDistributionFinished (  ) external view returns ( bool );
  function isLiquidityInAvax (  ) external view returns ( bool );
  function isOverLiquified ( uint256 target, uint256 accuracy ) external view returns ( bool );
  function liquidityFee (  ) external view returns ( uint256 );
  function liquidityReceiver (  ) external view returns ( address );
  function manualRebase (  ) external;
  function manualSync (  ) external;
  function mint ( address recipient, uint256 amount ) external;
  function name (  ) external view  returns  ( string memory);
  function nextRebase (  ) external view returns ( uint256 );
  function owner (  ) external view returns ( address );
  function pair (  ) external view returns ( address );
  function rebaseFrequency (  ) external view returns ( uint256 );
  function removeMinter (address) external;
  function renounceOwnership (  ) external;
  function rewardYield (  ) external view returns ( uint256 );
  function rewardYieldDenominator (  ) external view returns ( uint256 );
  function riskFreeValueReceiver (  ) external view returns ( address );
  function router (  ) external view returns ( address );
  function sellFeeTreasuryAdded (  ) external view returns ( uint256 );
  function setAutoRebase ( bool _autoRebase ) external;
  function setAutomatedMarketMakerPair ( address _pair, bool _value ) external;
  function setFeeExempt ( address _addr, bool _value ) external;
  function setFeeReceivers ( address _liquidityReceiver, address _treasuryReceiver, address _riskFreeValueReceiver ) external;
  function setFees ( uint256 _liquidityFee, uint256 _riskFreeValue, uint256 _treasuryFee, uint256 _sellFeeTreasuryAdded, uint256 _feeDenominator ) external;
  function setInitialDistributionFinished ( bool _value ) external;
  function setIsLiquidityInAvax ( bool _value ) external;
  function setNextRebase ( uint256 _nextRebase ) external;
  function setRebaseFrequency ( uint256 _rebaseFrequency ) external;
  function setRewardYield ( uint256 _rewardYield, uint256 _rewardYieldDenominator ) external;
  function setSwapBackSettings ( bool _enabled, uint256 _num, uint256 _denom ) external;
  function setTargetLiquidity ( uint256 target, uint256 accuracy ) external;
  function swapEnabled (  ) external view returns ( bool );
  function symbol (  ) external view returns ( string memory);
  function totalBuyFee (  ) external view returns ( uint256 );
  function totalSellFee (  ) external view returns ( uint256 );
  function totalSupply (  ) external view returns ( uint256 );
  function transfer ( address to, uint256 value ) external returns ( bool );
  function transferFrom ( address from, address to, uint256 value ) external returns ( bool );
  function transferOwnership ( address newOwner ) external;
  function treasuryFee (  ) external view returns ( uint256 );
  function treasuryReceiver (  ) external view returns ( address );
  function usdtToken (  ) external view returns ( address );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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