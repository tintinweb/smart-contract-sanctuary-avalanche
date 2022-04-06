/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-05
*/

// File: @boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
// a library for performing overflow-safe math, updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math)
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {require(b == 0 || (c = a * b)/b == a, "BoringMath: Mul Overflow");}
    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }
    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }
    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }
}

library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

// File: @boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol


pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // EIP 2612
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// File: @boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol

pragma solidity 0.6.12;
library BoringERC20 {
    function safeSymbol(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// File: @boringcrypto/boring-solidity/contracts/BoringBatchable.sol


// Audit on 5-Jan-2021 by Keno and BoringCrypto

// P1 - P3: OK
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
// solhint-disable avoid-low-level-calls
// T1 - T4: OK
contract BaseBoringBatchable {
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }    
    
    // F3 - F9: OK
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C1 - C21: OK
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns(bool[] memory successes, bytes[] memory results) {
        // Interactions
        successes = new bool[](calls.length);
        results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            require(success || !revertOnFail, _getRevertMsg(result));
            successes[i] = success;
            results[i] = result;
        }
    }
}

// T1 - T4: OK
contract BoringBatchable is BaseBoringBatchable {
    // F1 - F9: OK
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    // C1 - C21: OK
    function permitToken(IERC20 token, address from, address to, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        // Interactions
        // X1 - X5
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

// File: @boringcrypto/boring-solidity/contracts/BoringOwnable.sol


// Audit on 5-Jan-2021 by Keno and BoringCrypto

// P1 - P3: OK
pragma solidity 0.6.12;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

// T1 - T4: OK
contract BoringOwnableData {
    // V1 - V5: OK
    address public owner;
    // V1 - V5: OK
    address public pendingOwner;
}

// T1 - T4: OK
contract BoringOwnable is BoringOwnableData {
    // E1: OK
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;
        
        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    // M1 - M5: OK
    // C1 - C21: OK
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// File: contracts/libraries/SignedSafeMath.sol


pragma solidity 0.6.12;

library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }

    function toUInt256(int256 a) internal pure returns (uint256) {
        require(a >= 0, "Integer < 0");
        return uint256(a);
    }
}

// File: contracts/libraries/multiSignatureClient.sol

pragma solidity 0.6.12;

interface IMultiSignature{
    function getValidSignature(bytes32 msghash,uint256 lastIndex) external view returns(uint256);
}
contract multiSignatureClient{
    bytes32 private constant multiSignaturePositon = keccak256("org.hexagon.multiSignature.storage");
    constructor(address multiSignature) public {
        require(multiSignature != address(0),"multiSignatureClient : Multiple signature contract address is zero!");
        saveValue(multiSignaturePositon,uint256(multiSignature));
    }    
    function getMultiSignatureAddress()public view returns (address){
        return address(getValue(multiSignaturePositon));
    }
    modifier validCall(){
        checkMultiSignature();
        _;
    }
    function checkMultiSignature() internal {
        uint256 value;
        assembly {
            value := callvalue()
        }
        bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, address(this),value,msg.data));
        address multiSign = getMultiSignatureAddress();
        uint256 index = getValue(msgHash);
        uint256 newIndex = IMultiSignature(multiSign).getValidSignature(msgHash,index);
        require(newIndex > 0, "multiSignatureClient : This tx is not aprroved");
        saveValue(msgHash,newIndex);
    }
    function saveValue(bytes32 position,uint256 value) internal 
    {
        assembly {
            sstore(position, value)
        }
    }
    function getValue(bytes32 position) internal view returns (uint256 value) {
        assembly {
            value := sload(position)
        }
    }
}

// File: contracts/libraries/proxyOwner.sol

pragma solidity 0.6.12;

/**
 * @title  proxyOwner Contract

 */

contract proxyOwner is multiSignatureClient{
    bytes32 private constant proxyOwnerPosition  = keccak256("org.hexagon.Owner.storage");
    bytes32 private constant proxyOriginPosition0  = keccak256("org.hexagon.Origin.storage.0");
    bytes32 private constant proxyOriginPosition1  = keccak256("org.hexagon.Origin.storage.1");
    uint256 private constant oncePosition  = uint256(keccak256("org.hexagon.Once.storage"));
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OriginTransferred(address indexed previousOrigin, address indexed newOrigin);
    constructor(address multiSignature,address origin0,address origin1) multiSignatureClient(multiSignature) public {
        _setProxyOwner(msg.sender);
        _setProxyOrigin(address(0),origin0);
        _setProxyOrigin(address(0),origin1);
    }
    /**
     * @dev Allows the current owner to transfer ownership
     * @param _newOwner The address to transfer ownership to
     */

    function transferOwnership(address _newOwner) public onlyMulSigOwner
    {
        _setProxyOwner(_newOwner);
    }
    function _setProxyOwner(address _newOwner) internal 
    {
        emit OwnershipTransferred(mulsigOwner(),_newOwner);
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newOwner)
        }
    }
    function mulsigOwner() public view returns (address _owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            _owner := sload(position)
        }
    }
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyMulSigOwner() {
        require (isOwner(),"proxyOwner: caller must be the proxy owner and a contract and not expired");
        _;
    }
    function transferOrigin(address _oldOrigin,address _newOrigin) public onlyOrigin
    {
        _setProxyOrigin(_oldOrigin,_newOrigin);
    }
    function _setProxyOrigin(address _oldOrigin,address _newOrigin) internal 
    {
        emit OriginTransferred(_oldOrigin,_newOrigin);
        (address _origin0,address _origin1) = txOrigin();
        if (_origin0 == _oldOrigin){
            bytes32 position = proxyOriginPosition0;
            assembly {
                sstore(position, _newOrigin)
            }
        }else if(_origin1 == _oldOrigin){
            bytes32 position = proxyOriginPosition1;
            assembly {
                sstore(position, _newOrigin)
            }            
        }else{
            require(false,"OriginTransferred : old origin is illegal address!");
        }
    }
    function txOrigin() public view returns (address _origin0,address _origin1) {
        bytes32 position0 = proxyOriginPosition0;
        bytes32 position1 = proxyOriginPosition1;
        assembly {
            _origin0 := sload(position0)
            _origin1 := sload(position1)
        }
    }
    modifier originOnce() {
        require (isOrigin(),"proxyOwner: caller is not the tx origin!");
        uint256 key = oncePosition+uint32(msg.sig);
        require (getValue(bytes32(key))==0, "proxyOwner : This function must be invoked only once!");
        saveValue(bytes32(key),1);
        _;
    }
    function isOrigin() public view returns (bool){
        (address _origin0,address _origin1) = txOrigin();
        return  msg.sender == _origin0 || msg.sender == _origin1;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == mulsigOwner();//&& isContract(msg.sender);
    }
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOrigin() {
        require (isOrigin(),"proxyOwner: caller is not the tx origin!");
        checkMultiSignature();
        _;
    }
    modifier OwnerOrOrigin(){
        if (isOwner()){
            //allow owner to set once
            uint256 key = oncePosition+uint32(msg.sig);
            require (getValue(bytes32(key))==0, "proxyOwner : This function must be invoked only once!");
            saveValue(bytes32(key),1);
        }else if(isOrigin()){
            checkMultiSignature();
        }else{
            require(false,"proxyOwner: caller is not owner or origin");
        }
        _;
    }
    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: contracts/interfaces/IRewarder.sol



pragma solidity 0.6.12;

interface IRewarder {
    using BoringERC20 for IERC20;
    function onFlakeReward(uint256 pid, address user, address recipient, uint256 oldAmount, uint256 newLpAmount,bool bHarvest) external;
    function pendingTokens(uint256 pid, address user, uint256 flakeAmount) external view returns (IERC20[] memory, uint256[] memory);
}

// File: contracts/interfaces/IMiniChefV2.sol

pragma solidity 0.6.12;

interface IMiniChefV2 {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        uint128 accFlakePerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }

    function poolLength() external view returns (uint256);
    function updatePool(uint256 pid) external returns (IMiniChefV2.PoolInfo memory);
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function deposit(uint256 pid, uint256 amount, address to) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
    function harvest(uint256 pid, address to) external;
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;
    function emergencyWithdraw(uint256 pid, address to) external;
    function onTransfer(uint256 pid,address from,address to) external;
}

// File: contracts/farm/lpGauge.sol

pragma solidity 0.6.12;


contract lpGauge is BoringOwnable{
    modifier notZeroAddress(address inputAddress) {
        require(inputAddress != address(0), "Coin : input zero address");
        _;
    }

    // --- ERC20 Data ---
    // The name of this coin
    string  public name;
    // The symbol of this coin
    string  public symbol;
    // The version of this Coin contract
    string  public constant version = "1";
    // The number of decimals that this coin has
    uint8   public constant decimals = 18;
    // The total supply of this coin
    uint256 public totalSupply;
    uint256 public pid;

    // Mapping of coin balances
    mapping (address => uint256)                      public balanceOf;
    // Mapping of allowances
    mapping (address => mapping (address => uint256)) public allowance;
    // Mapping of nonces used for permits
    mapping (address => uint256)                      public nonces;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event Approval(address indexed src, address indexed guy, uint256 amount);
    event Transfer(address indexed src, address indexed dst, uint256 amount);

    // --- Math ---
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "lpGauge/add-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "lpGauge/sub-underflow");
    }

    constructor(string memory name_,
        string memory symbol_,
        uint256 pid_
      )public {
        name          = name_;
        symbol        = symbol_;
        pid = pid_;
    }

    // --- Token ---
    /*
    * @notice Transfer coins to another address
    * @param dst The address to transfer coins to
    * @param amount The amount of coins to transfer
    */
    function transfer(address dst, uint256 amount) external returns (bool) {
        return transferFrom(msg.sender, dst, amount);
    }
    /*
    * @notice Transfer coins from a source address to a destination address (if allowed)
    * @param src The address from which to transfer coins
    * @param dst The address that will receive the coins
    * @param amount The amount of coins to transfer
    */
    function transferFrom(address src, address dst, uint256 amount)
        public returns (bool)
    {
        require(dst != address(0), "Coin/null-dst");
        require(dst != address(this), "Coin/dst-cannot-be-this-contract");
        require(balanceOf[src] >= amount, "Coin/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != uint256(-1)) {
            require(allowance[src][msg.sender] >= amount, "Coin/insufficient-allowance");
            allowance[src][msg.sender] = subtract(allowance[src][msg.sender], amount);
        }
        balanceOf[src] = subtract(balanceOf[src], amount);
        balanceOf[dst] = addition(balanceOf[dst], amount);
        IMiniChefV2(owner).onTransfer(pid,src,dst);
        emit Transfer(src, dst, amount);
        return true;
    }
    /*
    * @notice Mint new coins
    * @param usr The address for which to mint coins
    * @param amount The amount of coins to mint
    */
    function mint(address usr, uint256 amount) external onlyOwner notZeroAddress(usr) {
        balanceOf[usr] = addition(balanceOf[usr], amount);
        totalSupply    = addition(totalSupply, amount);
        emit Transfer(address(0), usr, amount);
    }
    /*
    * @notice Burn coins from an address
    * @param usr The address that will have its coins burned
    * @param amount The amount of coins to burn
    */
    function burn(address usr, uint256 amount) onlyOwner external {
        require(balanceOf[usr] >= amount, "Coin/insufficient-balance");
        balanceOf[usr] = subtract(balanceOf[usr], amount);
        totalSupply    = subtract(totalSupply, amount);
        if (owner != msg.sender){
            IMiniChefV2(owner).onTransfer(pid,usr,address(0));
        }
        emit Transfer(usr, address(0), amount);
    }
    /*
    * @notice Change the transfer/burn allowance that another address has on your behalf
    * @param usr The address whose allowance is changed
    * @param amount The new total allowance for the usr
    */
    function approve(address usr, uint256 amount) external notZeroAddress(usr) returns (bool)  {
        allowance[msg.sender][usr] = amount;
        emit Approval(msg.sender, usr, amount);
        return true;
    }

}

// File: contracts/interfaces/IBoost.sol


pragma solidity 0.6.12;

interface IBoost {
    function getTotalBoostedAmount(uint256 _pid,address _user,uint256 _lpamount,uint256 _baseamount)external view returns(uint256,uint256);
    function boostDeposit(uint256 _pid,address _account,uint256 _amount) external;

    function boostWithdraw(uint256 _pid,address _account,uint256 _amount) external;
    function boostStakedFor(uint256 _pid,address _account) external view returns (uint256);
    function boostTotalStaked(uint256 _pid) external view returns (uint256);
    function getBoostToken(uint256 _pid) external view returns(address);

    function setBoostFunctionPara(uint256 _pid,uint256 _para0,uint256 _para1, uint256 _para2) external;
    function setBoostFarmFactorPara(uint256 _pid, uint256 _lockTime, bool  _enableTokenBoost, address _boostToken, uint256 _minBoostAmount, uint256 _maxIncRatio) external;
    function setWhiteListMemberStatus(uint256 _pid,address _user,bool _status)  external;

    function setFixedWhitelistPara(uint256 _pid,uint256 _incRatio,uint256 _whiteListfloorLimit) external;
    function setFixedTeamRatio(uint256 _pid,uint256 _ratio) external;
    function setMulsigAndFarmChef ( address _multiSignature,  address _farmChef) external;

    function whiteListLpUserInfo(uint256 _pid,address _user) external view returns (bool);

}

// File: contracts/farm/MiniChefV2.sol

pragma solidity 0.6.12;








//interface IMigratorChef {
//    // Take the current LP token address and return the new LP token address.
//    // Migrator should have full access to the caller's LP token.
//    function migrate(IERC20 token) external returns (IERC20);
//}


/// @notice The (older) MasterChef contract gives out a constant number of FLAKE tokens per block.
/// It is the only address with minting rights for FLAKE.
/// The idea for this MasterChef V2 (MCV2) contract is therefore to be the owner of a dummy token
/// that is deposited into the MasterChef V1 (MCV1) contract.
/// The allocation point for this pool on MCV1 is the total allocation point for all pools that receive double incentives.
contract MiniChefV2 is BoringOwnable, BoringBatchable /*,proxyOwner*/ {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringERC20 for IERC20;
    using SignedSafeMath for int256;

    /// @notice Info of each MCV2 user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of FLAKE entitled to the user.
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    /// @notice Info of each MCV2 pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of FLAKE to distribute per block.
    struct PoolInfo {
        uint128 accFlakePerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }

    IBoost public booster;
    address public royaltyReciever;
    address public safeMulsig;
    //for test or use safe mulsig
    modifier onlyOrigin() {
        require(msg.sender==safeMulsig, "not setting safe contract");
        _;
    }

    /// @notice Address of FLAKE contract.
    IERC20 public FLAKE;
    // @notice The migrator contract. It has a lot of power. Can only be set through governance (owner).
   // IMigratorChef public migrator;

    /// @notice Info of each MCV2 pool.
    PoolInfo[] public poolInfo;
    /// @notice Address of the LP token for each MCV2 pool.
    IERC20[] public lpToken;
        /// @notice Address of the LP Gauge for each MCV2 pool.
    lpGauge[] public lpGauges;
    /// @notice Address of each `IRewarder` contract in MCV2.
    IRewarder[] public rewarder;

    /// @notice Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    /// @dev Tokens added
    mapping (address => bool) public addedTokens;

    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    uint256 public flakePerSecond;
    uint256 private constant ACC_FLAKE_PRECISION = 1e12;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount,uint256 boostedAmount);
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken, IRewarder indexed rewarder);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint, IRewarder indexed rewarder, bool overwrite);
    event LogUpdatePool(uint256 indexed pid, uint64 lastRewardTime, uint256 lpSupply, uint256 accFlakePerShare);
    event LogFlakePerSecond(uint256 flakePerSecond);

    event OnBalanceChange(address indexed user, uint256 indexed pid, uint256 amount, bool increase);

    event SetBooster(address indexed booster);

    /// @param _flake The FLAKE token contract address.
    constructor(address _multiSignature,
                IERC20 _flake)
        public
    {
        FLAKE = _flake;
        safeMulsig = _multiSignature;
    }

    function setMulsigAndRewardToken(address _multiSignature,
                                     address _flake)
        onlyOrigin
        public
    {
        FLAKE = IERC20(_flake);
        safeMulsig = _multiSignature;
    }

    /// @notice Returns the number of MCV2 pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    /// @notice Add a new LP to the pool. Can only be called by the owner.
    /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    /// @param allocPoint AP of the new pool.
    /// @param _lpToken Address of the LP ERC-20 token.
    /// @param _rewarder Address of the rewarder delegate.
    function add(uint256 allocPoint, IERC20 _lpToken, IRewarder _rewarder) public onlyOrigin {
        require(addedTokens[address(_lpToken)] == false, "Token already added");
        totalAllocPoint = totalAllocPoint.add(allocPoint);
        lpToken.push(_lpToken);
        rewarder.push(_rewarder);
        uint256 _pid = lpToken.length.sub(1);
        string memory gaugeName = string(abi.encodePacked("lpGauge",toString(_pid)));
        lpGauges.push(new lpGauge(gaugeName,gaugeName,_pid));

        poolInfo.push(PoolInfo({
            allocPoint: allocPoint.to64(),
            lastRewardTime: block.timestamp.to64(),
            accFlakePerShare: 0
        }));
        addedTokens[address(_lpToken)] = true;
        emit LogPoolAddition(_pid, allocPoint, _lpToken, _rewarder);
    }

    /// @notice Update the given pool's FLAKE allocation point and `IRewarder` contract. Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    /// @param _rewarder Address of the rewarder delegate.
    /// @param overwrite True if _rewarder should be `set`. Otherwise `_rewarder` is ignored.
    function set(uint256 _pid, uint256 _allocPoint, IRewarder _rewarder, bool overwrite) public onlyOrigin {
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint.to64();
        if (overwrite) { rewarder[_pid] = _rewarder; }
        emit LogSetPool(_pid, _allocPoint, overwrite ? _rewarder : rewarder[_pid], overwrite);
    }

    /// @notice Sets the FLAKE per second to be distributed. Can only be called by the owner.
    /// @param _flakePerSecond The amount of FLAKE to be distributed per second.
    function setFlakePerSecond(uint256 _flakePerSecond) public onlyOrigin {
        flakePerSecond = _flakePerSecond;
        emit LogFlakePerSecond(_flakePerSecond);
    }

    /// @notice Set the `migrator` contract. Can only be called by the owner.
    /// @param _migrator The contract address to set.
//    function setMigrator(IMigratorChef _migrator) public onlyOrigin {
//        migrator = _migrator;
//    }
//
//    /// @notice Migrate LP token to another LP contract through the `migrator` contract.
//    /// @param _pid The index of the pool. See `poolInfo`.
//    function migrate(uint256 _pid) public {
//        require(address(migrator) != address(0), "IMiniChefV2: no migrator set");
//        IERC20 _lpToken = lpToken[_pid];
//        uint256 bal = _lpToken.balanceOf(address(this));
//        _lpToken.approve(address(migrator), bal);
//        IERC20 newLpToken = migrator.migrate(_lpToken);
//        require(bal == newLpToken.balanceOf(address(this)), "IMiniChefV2: migrated balance must match");
//        require(addedTokens[address(newLpToken)] == false, "Token already added");
//        addedTokens[address(newLpToken)] = true;
//        addedTokens[address(_lpToken)] = false;
//        lpToken[_pid] = newLpToken;
//    }

    /// @notice View function to see pending FLAKE on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// return pending FLAKE reward for a given user.
    function pendingFlake(uint256 _pid, address _user) external view returns (uint256 wholePending,uint256 incAmount,uint256 teamRoyalty) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accFlakePerShare = pool.accFlakePerShare;
        uint256 lpSupply = lpGauges[_pid].totalSupply();
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint256 time = block.timestamp.sub(pool.lastRewardTime);
            uint256 flakeReward = time.mul(flakePerSecond).mul(pool.allocPoint) / totalAllocPoint;
            accFlakePerShare = accFlakePerShare.add(flakeReward.mul(ACC_FLAKE_PRECISION) / lpSupply);
        }
        uint256 pending = int256(user.amount.mul(accFlakePerShare) / ACC_FLAKE_PRECISION).sub(user.rewardDebt).toUInt256();

        ///////////////////////////////////////////////////////////////////////////
        (wholePending,incAmount,teamRoyalty) = boostRewardAndGetTeamRoyalty(_pid,_user,user.amount,pending);
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
    function massUpdatePools(uint256[] calldata pids) external {
        uint256 len = pids.length;
        for (uint256 i = 0; i < len; ++i) {
            updatePool(pids[i]);
        }
    }

    /// @notice Update reward variables of the given pool.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function updatePool(uint256 pid) public returns (PoolInfo memory pool) {
        pool = poolInfo[pid];
        if (block.timestamp > pool.lastRewardTime) {
            uint256 lpSupply = lpGauges[pid].totalSupply();
            if (lpSupply > 0) {
                uint256 time = block.timestamp.sub(pool.lastRewardTime);
                uint256 flakeReward = time.mul(flakePerSecond).mul(pool.allocPoint) / totalAllocPoint;
                pool.accFlakePerShare = pool.accFlakePerShare.add((flakeReward.mul(ACC_FLAKE_PRECISION) / lpSupply).to128());
            }
            pool.lastRewardTime = block.timestamp.to64();
            poolInfo[pid] = pool;
            emit LogUpdatePool(pid, pool.lastRewardTime, lpSupply, pool.accFlakePerShare);
        }
    }

    function onTransfer(uint256 pid,address from,address to) external {
        //check sender permission
//        require(address(lpGauges[pid])==msg.sender,"have no permission!");

        PoolInfo memory pool = updatePool(pid);
        onBalanceChange(pool,pid,from);
        onBalanceChange(pool,pid,to);
    }

    function onBalanceChange(PoolInfo memory pool,uint256 pid,address _usr)internal {
        if (_usr != address(0)){
            UserInfo storage user = userInfo[pid][_usr];
            uint256 amount = lpGauges[pid].balanceOf(_usr);
            if (amount > user.amount){
                depoistPending(pool,pid,amount-user.amount,_usr);

                emit OnBalanceChange(_usr,pid,amount-user.amount, true);

            }else if (amount<user.amount){
                withdrawPending(pool,pid,user.amount-amount,_usr);

                emit OnBalanceChange(_usr,pid,user.amount-amount, false);
            }
        }

    }
    /// @notice Deposit LP tokens to MCV2 for FLAKE allocation.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to deposit.
    /// @param to The receiver of `amount` deposit benefit.
    function deposit(uint256 pid, uint256 amount, address to) public {
        PoolInfo memory pool = updatePool(pid);
        //UserInfo storage user = userInfo[pid][to];

        depoistPending(pool,pid,amount,to);
        lpGauges[pid].mint(to,amount);
        lpToken[pid].safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, pid, amount, to);
    }

    function depoistPending(PoolInfo memory pool,uint256 pid, uint256 amount, address to)internal {
        UserInfo storage user = userInfo[pid][to];
        uint256 oldAmount = user.amount;
        user.amount = user.amount.add(amount);
        user.rewardDebt = user.rewardDebt.add(int256(amount.mul(pool.accFlakePerShare) / ACC_FLAKE_PRECISION));

        // Interactions
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onFlakeReward(pid, to, to, oldAmount, user.amount,false);
        }
    }
    /// @notice Withdraw LP tokens from MCV2.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens.
    function withdraw(uint256 pid, uint256 amount, address to) public {
        PoolInfo memory pool = updatePool(pid);
        withdrawPending(pool,pid,amount,msg.sender);
        lpGauges[pid].burn(msg.sender,amount);
        lpToken[pid].safeTransfer(to, amount);

        emit Withdraw(msg.sender, pid, amount, to);
    }

    function withdrawPending(PoolInfo memory pool,uint256 pid, uint256 amount, address _usr) internal {
        UserInfo storage user = userInfo[pid][_usr];
        // Effects
        uint256 oldAmount = user.amount;
        user.rewardDebt = user.rewardDebt.sub(int256(amount.mul(pool.accFlakePerShare) / ACC_FLAKE_PRECISION));
        user.amount = user.amount.sub(amount);

        // Interactions
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onFlakeReward(pid, _usr, _usr, oldAmount, user.amount,false);
        }
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of FLAKE rewards.
    function harvest(uint256 pid,address to) public {
        harvestAccount(pid,msg.sender,to);
    }

    function harvestAccount(uint256 pid,address account,address to) internal {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][account];
        int256 accumulatedFlake = int256(user.amount.mul(pool.accFlakePerShare) / ACC_FLAKE_PRECISION);
        uint256 _pendingFlake = accumulatedFlake.sub(user.rewardDebt).toUInt256();
        /////////////////////////////////////////////////////////////////////////
        //get the reward after boost
        uint256 incReward = 0;
        uint256 teamRoyalty = 0;
        (_pendingFlake,incReward,teamRoyalty) = boostRewardAndGetTeamRoyalty(pid,account,user.amount,_pendingFlake);
        //for team royalty
        if(teamRoyalty>0&&royaltyReciever!=address(0)) {
            FLAKE.safeTransfer(royaltyReciever, teamRoyalty);
        }

        //////////////////////////////////////////////////////////////////////////

        // Effects
        user.rewardDebt = accumulatedFlake;

        // Interactions
        if (_pendingFlake != 0) {
            FLAKE.safeTransfer(to, _pendingFlake);
        }

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onFlakeReward( pid, account, to, user.amount, user.amount,true);
        }

        emit Harvest(account, pid, _pendingFlake,incReward);
    }

    /// @notice Withdraw LP tokens from MCV2 and harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens and FLAKE rewards.
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 oldAmount = user.amount;
        int256 accumulatedFlake = int256(user.amount.mul(pool.accFlakePerShare) / ACC_FLAKE_PRECISION);
        uint256 _pendingFlake = accumulatedFlake.sub(user.rewardDebt).toUInt256();
        ////////////////////////////////////////////////////////////////////////
        //get the reward after boost
        uint256 incReward = 0;
        uint256 teamRoyalty = 0;
        (_pendingFlake,incReward,teamRoyalty) = boostRewardAndGetTeamRoyalty(pid,msg.sender,user.amount,_pendingFlake);
        //for team royalty
        if(teamRoyalty>0&&royaltyReciever!=address(0)) {
            FLAKE.safeTransfer(royaltyReciever, teamRoyalty);
        }
        //////////////////////////////////////////////////////////////////////////
        // Effects
        user.rewardDebt = accumulatedFlake.sub(int256(amount.mul(pool.accFlakePerShare) / ACC_FLAKE_PRECISION));
        user.amount = user.amount.sub(amount);
        // Interactions
        FLAKE.safeTransfer(to, _pendingFlake);

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onFlakeReward(pid, msg.sender, to, oldAmount, user.amount,true);
        }


        lpToken[pid].safeTransfer(to, amount);
        lpGauges[pid].burn(msg.sender,amount);
        emit Withdraw(msg.sender, pid, amount, to);
        emit Harvest(msg.sender, pid, _pendingFlake,incReward);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of the LP tokens.
    function emergencyWithdraw(uint256 pid, address to) public {
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onFlakeReward(pid, msg.sender, to, 0, 0,false);
        }
        lpGauges[pid].burn(msg.sender,amount);
        // Note: transfer can fail or succeed if `amount` is zero.
        lpToken[pid].safeTransfer(to, amount);
        emit EmergencyWithdraw(msg.sender, pid, amount, to);
    }
///////////////////////////////////////////////////////////////////////////////
    function setBooster(address _booster) public onlyOrigin {
        booster = IBoost(_booster);
        emit SetBooster(_booster);
    }

    function setRoyaltyReciever(address _royaltyReciever) public onlyOrigin {
        royaltyReciever = _royaltyReciever;
    }

    function setBoostFunctionPara(uint256 _pid,uint256 _para0,uint256 _para1, uint256 _para2) external onlyOrigin {
        booster.setBoostFunctionPara(_pid,_para0,_para1,_para2);
    }

    function setBoostFarmFactorPara(uint256 _pid, uint256 _lockTime, bool  _enableTokenBoost, address _boostToken, uint256 _minBoostAmount, uint256 _maxIncRatio) external onlyOrigin {
        booster.setBoostFarmFactorPara(_pid, _lockTime,  _enableTokenBoost, _boostToken, _minBoostAmount, _maxIncRatio);
        //init to defualt vault
        booster.setBoostFunctionPara(_pid,0,0,0);
    }

    function setWhiteListMemberStatus(uint256 _pid,address _user,bool _status)  external onlyOrigin {
        //settle for the user
        harvest(_pid, _user);

        booster.setWhiteListMemberStatus(_pid,_user,_status);
    }

    function setWhiteList(uint256 _pid,address[] memory _user) external onlyOrigin {
        require(_user.length>0,"array length is 0");
        for(uint256 i=0;i<_user.length;i++) {

            if(booster.whiteListLpUserInfo(_pid,_user[i])) {
                //settle for the user
                harvest(_pid, _user[i]);
            }

            booster.setWhiteListMemberStatus(_pid,_user[i],true);
        }
    }

    function setFixedWhitelistPara(uint256 _pid,uint256 _incRatio,uint256 _whiteListfloorLimit) external onlyOrigin {
        booster.setFixedWhitelistPara(_pid,_incRatio,_whiteListfloorLimit);
    }

    function setFixedTeamRatio(uint256 _pid,uint256 _ratio) external onlyOrigin {
        booster.setFixedTeamRatio(_pid,_ratio);
    }

    function boostRewardAndGetTeamRoyalty(uint256 _pid,address _user,uint256 _userLpAmount,uint256 _pendingFlake) view public returns(uint256,uint256,uint256) {
        if(address(booster)==address(0)) {
            return (_pendingFlake,0,0);
        }
        //record init reward
        uint256 incReward = _pendingFlake;
        uint256 teamRoyalty = 0;
        (_pendingFlake,teamRoyalty) = booster.getTotalBoostedAmount(_pid,_user,_userLpAmount,_pendingFlake);
        //(_pendingFlake+teamRoyalty) is total (boosted reward inclued baseAnount + init reward)
        incReward = _pendingFlake.add(teamRoyalty).sub(incReward);

        return (_pendingFlake,incReward,teamRoyalty);
    }

    function boostDeposit(uint256 _pid,uint256 _amount) external {
        require(address(booster)!=address(0),"booster is not set");

        //need to harvest when boost amount changed
        harvest(_pid, msg.sender);

        booster.boostDeposit(_pid,msg.sender,_amount);

        address boostToken = booster.getBoostToken(_pid);
        IERC20(boostToken).safeTransferFrom(msg.sender,address(booster), _amount);
    }


    function boostWithdraw(uint256 _pid,uint256 _amount) external {
        require(address(booster)!=address(0),"booster is not set");

        //need to harvest when boost amount changed
        harvest(_pid, msg.sender);

        booster.boostWithdraw(_pid,msg.sender,_amount);
    }

    function boostStakedFor(uint256 _pid,address _account) external view returns (uint256) {
        require(address(booster)!=address(0),"booster is not set");
        return booster.boostStakedFor(_pid,_account);
    }

    function boostTotalStaked(uint256 _pid) external view returns (uint256) {
        require(address(booster)!=address(0),"booster is not set");
        return booster.boostTotalStaked(_pid);
    }

    function getPoolId(address _lp) external view returns (uint256) {
        for(uint256 i=0;i<lpToken.length;i++) {
            if(_lp==address(lpToken[i])) {
                return i;
            }
        }
        return uint256(-1);
    }


}