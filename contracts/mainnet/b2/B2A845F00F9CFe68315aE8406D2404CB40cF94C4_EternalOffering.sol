/**
 *Submitted for verification at snowtrace.io on 2022-04-15
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IJoePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// File: @traderjoe-xyz/core/contracts/traderjoe/interfaces/IJoeFactory.sol



interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

// File: @traderjoe-xyz/core/contracts/traderjoe/interfaces/IJoeRouter01.sol



interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// File: @traderjoe-xyz/core/contracts/traderjoe/interfaces/IJoeRouter02.sol




interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// File: github/TheGrandNobody/eternal-contracts/contracts/interfaces/IEternalTreasury.sol

/**
 * @dev Eternal Treasury interface
 * @author Nobody (me)
 * @notice Methods are used for all treasury functions
 */
interface IEternalTreasury {
    // Provides liquidity for a given liquid gage and transfers instantaneous rewards to the receiver
    function fundEternalLiquidGage(address _gage, address user, address asset, uint256 amount, uint256 risk, uint256 bonus) external payable;
    // Used by gages to compute and distribute ETRNL liquid gage rewards appropriately
    function settleGage(address receiver, uint256 id, bool winner) external;
    // Stake a given amount of ETRNL
    function stake(uint256 amount) external;
    // Unstake a given amount of ETRNL and withdraw staking rewards proportional to the amount (in ETRNL)
    function unstake(uint256 amount) external;
    // View the ETRNL/AVAX pair address
    function viewPair() external view returns (address);
    // View whether a liquidity swap is in progress
    function viewUndergoingSwap() external view returns (bool);
    // Provides liquidity for the ETRNL/AVAX pair for the ETRNL token contract
    function provideLiquidity(uint256 contractBalance) external;
    // Computes the minimum amount of two assets needed to provide liquidity given one asset amount
    function computeMinAmounts(address asset, address otherAsset, uint256 amountAsset, uint256 uncertainty) external view returns (uint256 minOtherAsset, uint256 minAsset, uint256 amountOtherAsset);
    // Converts a given staked amount into the reserve number space
    function convertToReserve(uint256 amount) external view returns (uint256);
    // Converts a given reserve amount into the regular number space (staked)
    function convertToStaked(uint256 reserveAmount) external view returns (uint256);
    // Allows the withdrawal of AVAX in the contract
    function withdrawAVAX(address recipient, uint256 amount) external;
    // Allows the withdrawal of an asset present in the contract
    function withdrawAsset(address asset, address recipient, uint256 amount) external;
    // Adds or subtracts a given amount of ETRNL from the treasury's reserves
    function updateReserves(address user, uint256 amount, uint256 reserveAmount, bool add) external;

    // Signals that part of the locked AVAX balance has been cleared to a given address by decision of governance
    event AVAXTransferred(uint256 amount, address recipient);
    // Signals that some of an asset balance has been sent to a given address by decision of governance
    event AssetTransferred(address asset, uint256 amount, address recipient);
}
// File: github/TheGrandNobody/eternal-contracts/contracts/interfaces/IEternalStorage.sol



/**
 * @dev Eternal Storage interface
 * @author Nobody (me)
 * @notice Methods are used for all of Eternal's variable storage
 */
interface IEternalStorage {
    // Scalar setters
    function setUint(bytes32 entity, bytes32 key, uint256 value) external;
    function setInt(bytes32 entity, bytes32 key, int256 value) external;
    function setAddress(bytes32 entity, bytes32 key, address value) external;
    function setBool(bytes32 entity, bytes32 key, bool value) external;
    function setBytes(bytes32 entity, bytes32 key, bytes32 value) external;

    // Scalar getters
    function getUint(bytes32 entity, bytes32 key) external view returns (uint256);
    function getInt(bytes32 entity, bytes32 key) external view returns (int256);
    function getAddress(bytes32 entity, bytes32 key) external view returns (address);
    function getBool(bytes32 entity, bytes32 key) external view returns (bool);
    function getBytes(bytes32 entity, bytes32 key) external view returns (bytes32);

    // Array setters
    function setUintArrayValue(bytes32 key, uint256 index, uint256 value) external;
    function setIntArrayValue(bytes32 key, uint256 index, int256 value) external;
    function setAddressArrayValue(bytes32 key, uint256 index, address value) external;
    function setBoolArrayValue(bytes32 key, uint256 index, bool value) external;
    function setBytesArrayValue(bytes32 key, uint256 index, bytes32 value) external;

    // Array getters
    function getUintArrayValue(bytes32 key, uint256 index) external view returns (uint256);
    function getIntArrayValue(bytes32 key, uint256 index) external view returns (int256);
    function getAddressArrayValue(bytes32 key, uint256 index) external view returns (address);
    function getBoolArrayValue(bytes32 key, uint256 index) external view returns (bool);
    function getBytesArrayValue(bytes32 key, uint256 index) external view returns (bytes32);

    //Array Deleters
    function deleteUint(bytes32 key, uint256 index) external;
    function deleteInt(bytes32 key, uint256 index) external;
    function deleteAddress(bytes32 key, uint256 index) external;
    function deleteBool(bytes32 key, uint256 index) external;
    function deleteBytes(bytes32 key, uint256 index) external;

    //Array Length
    function lengthUint(bytes32 key) external view returns (uint256);
    function lengthInt(bytes32 key) external view returns (uint256);
    function lengthAddress(bytes32 key) external view returns (uint256);
    function lengthBool(bytes32 key) external view returns (uint256);
    function lengthBytes(bytes32 key) external view returns (uint256);
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: github/TheGrandNobody/eternal-contracts/contracts/interfaces/IGage.sol



/**
 * @dev Gage interface
 * @author Nobody (me)
 * @notice Methods are used for all gage contracts
 */
interface IGage {
    // Holds all possible statuses for a gage
    enum Status {
        Pending,
        Active,
        Closed
    }

    // Holds user-specific information with regards to the gage
    struct UserData {
        address asset;                       // The address of the asset used as deposit     
        uint256 amount;                      // The entry deposit (in tokens) needed to participate in this gage        
        uint256 risk;                        // The percentage (in decimal form) that is being risked in this gage (x 10 ** 4) 
        bool inGage;                         // Keeps track of whether the user is in the gage or not
    }         

    // Removes a user from the gage
    function exit() external;
    // View the user count in the gage whilst it is not Active
    function viewGageUserCount() external view returns (uint256);
    // View the total user capacity of the gage
    function viewCapacity() external view returns (uint256);
    // View the gage's status
    function viewStatus() external view returns (uint);
    // View whether the gage is a loyalty gage or not
    function viewLoyalty() external view returns (bool);
    // View a given user's gage data
    function viewUserData(address user) external view returns (address, uint256, uint256);

    // Signals the transition from 'Pending' to 'Active for a given gage
    event GageInitiated(uint256 id);
    // Signals the transition from 'Active' to 'Closed' for a given gage
    event GageClosed(uint256 id, address indexed winner); 
}
// File: github/TheGrandNobody/eternal-contracts/contracts/gages/Gage.sol








/**
 * @title Gage contract 
 * @author Nobody (me)
 * @notice Implements the basic necessities for any gage
 */
abstract contract Gage is Context, IGage {

/////–––««« Variables: Addresses and Interfaces »»»––––\\\\\

    // The Eternal Storage
    IEternalStorage public immutable eternalStorage;
    // The Eternal Treasury
    IEternalTreasury internal treasury;

/////–––««« Variables: Gage data »»»––––\\\\\

    // Holds all users' information in the gage
    mapping (address => UserData) internal userData;
    // The id of the gage
    uint256 internal immutable id;  
    // The maximum number of users in the gage
    uint256 internal immutable capacity; 
    // Keeps track of the number of users left in the gage
    uint256 internal users;
    // The state of the gage       
    Status internal status;
    // Determines whether the gage is a loyalty gage or not       
    bool private immutable loyalty;

/////–––««« Constructor »»»––––\\\\\
    
    constructor (uint256 _id, uint256 _users, address _eternalStorage, bool _loyalty) {
        require(_users > 1, "Gage needs at least two users");
        id = _id;
        capacity = _users;
        loyalty = _loyalty;
        eternalStorage = IEternalStorage(_eternalStorage);
    }   

/////–––««« Variable state-inspection functions »»»––––\\\\\

    /**
     * @notice View the number of stakeholders in the gage.
     * @return uint256 The number of stakeholders in the selected gage
     */
    function viewGageUserCount() external view override returns (uint256) {
        return users;
    }

    /**
     * @notice View the total user capacity of the gage.
     * @return uint256 The total user capacity
     */
    function viewCapacity() external view override returns (uint256) {
        return capacity;
    }

    /**
     * @notice View the status of the gage.
     * @return uint256 An integer indicating the status of the gage
     */
    function viewStatus() external view override returns (uint256) {
        return uint256(status);
    }

    /**
     * @notice View whether the gage is a loyalty gage or not.
     * @return bool True if the gage is a loyalty gage, else false
     */
    function viewLoyalty() external view override returns (bool) {
        return loyalty;
    }

    /**
     * @notice View a given user's gage data. 
     * @param user The address of the specified user
     * @return address The address of this user's deposited asset
     * @return uint256 The amount of this user's deposited asset
     * @return uint256 The risk percentage for this user
     */
    function viewUserData(address user) external view override returns (address, uint256, uint256) {
        UserData storage data = userData[user];
        return (data.asset, data.amount, data.risk);
    }
}
// File: github/TheGrandNobody/eternal-contracts/contracts/interfaces/ILoyaltyGage.sol




/**
 * @dev Loyalty Gage interface
 * @author Nobody (me)
 * @notice Methods are used for all loyalty gage contracts
 */
interface ILoyaltyGage is IGage {
    // Initializes the loyalty gage
    function initialize(address rAsset, address dAsset, uint256 rAmount, uint256 dAmount, uint256 rRisk, uint256 dRisk) external;
    // View the gage's minimum target supply meeting the percent change condition
    function viewTarget() external view returns (uint256);
}
// File: github/TheGrandNobody/eternal-contracts/contracts/gages/LoyaltyGage.sol





/**
 * @title Loyalty Gage contract
 * @author Nobody (me)
 * @notice A loyalty gage creates a healthy, symbiotic relationship between a distributor and a receiver
 */
contract LoyaltyGage is Gage, ILoyaltyGage {

/////–––««« Variables: Addresses and Interfaces »»»––––\\\\\

    // Address of the stakeholder which pays the discount in a loyalty gage
    address public immutable distributor;
    // Address of the stakeholder which benefits from the discount in a loyalty gage
    address public immutable receiver;
    // The asset used in the condition
    IERC20 private assetOfReference;

/////–––««« Variables: Condition computation »»»––––\\\\\

    // The percentage change condition for the total token supply (x 10 ** 11)
    uint256 public immutable percent;
    // The total supply at the time of the deposit
    uint256 private totalSupply;
    // Whether the token's supply is inflationary or deflationary
    bool public immutable inflationary;

/////–––««« Constructors & Initializers »»»––––\\\\\

    constructor(uint256 _id, uint256 _percent, uint256 _users, bool _inflationary, address _distributor, address _receiver, address _storage) Gage(_id, _users, _storage, true) {
        distributor = _distributor;
        receiver = _receiver;
        percent = _percent;
        inflationary = _inflationary;
    }
/////–––««« Variable state-inspection functions »»»––––\\\\\

    /**
     * @notice View the target supply plus/minus the percent change condition for the total token supply of the asset of reference.
     * @return uint256 The minimum target supply which meets the percent change condition
     */
    function viewTarget() public view override returns (uint256) {
        uint256 delta = (totalSupply * percent / (10 ** 11));
        return inflationary ? totalSupply + delta : totalSupply - delta;
    }
    
/////–––««« Gage-logic functions »»»––––\\\\\
    /**
     * @notice Initializes a loyalty gage for the receiver and distributor.
     * @param rAsset The address of the asset used as deposit by the receiver
     * @param dAsset The address of the asset used as deposit by the distributor
     * @param rAmount The receiver's chosen deposit amount 
     * @param dAmount The distributor's chosen deposit amount
     * @param rRisk The receiver's risk
     * @param dRisk The distributor's risk
     *
     * Requirements:
     *
     * - Only callable by an Eternal contract
     */
    function initialize(address rAsset, address dAsset, uint256 rAmount, uint256 dAmount, uint256 rRisk, uint256 dRisk) external override {
        bytes32 entity = keccak256(abi.encodePacked(address(eternalStorage)));
        bytes32 sender = keccak256(abi.encodePacked(_msgSender()));
        require(_msgSender() == eternalStorage.getAddress(entity, sender), "msg.sender must be from Eternal");

        treasury = IEternalTreasury(_msgSender());

        // Save receiver parameters and data
        userData[receiver].inGage = true;
        userData[receiver].amount = rAmount;
        userData[receiver].asset = rAsset;
        userData[receiver].risk = rRisk;

        // Save distributor parameters and data
        userData[distributor].inGage = true;
        userData[distributor].amount = dAmount;
        userData[distributor].asset = dAsset;
        userData[distributor].risk = dRisk;

        // Save liquid gage parameters
        assetOfReference = IERC20(dAsset);
        totalSupply = assetOfReference.totalSupply();

        users = 2;

        status = Status.Active;
        emit GageInitiated(id);
    }

    /**
     * @notice Closes this gage and determines the winner.
     *
     * Requirements:
     *
     * - Only callable by the receiver
     * - Gage must be active
     */
    function exit() external override {
        require(_msgSender() == receiver, "Only the receiver may exit");
        require(status == Status.Active, "Cannot exit an inactive gage");
        // Remove user from the gage first (prevent re-entrancy)
        userData[receiver].inGage = false;
        userData[distributor].inGage = false;
        // Calculate the target supply after the change in total supply of the asset of reference
        uint256 targetSupply = viewTarget();
        // Determine whether the user is the winner
        bool winner = inflationary ? assetOfReference.totalSupply() >= targetSupply : assetOfReference.totalSupply() <= targetSupply;
        emit GageClosed(id, winner ? receiver : distributor);
        status = Status.Closed;
        // Communicate with an external treasury which offers gages
        treasury.settleGage(receiver, id, winner);
    }
}
// File: github/TheGrandNobody/eternal-contracts/contracts/main/EternalOffering.sol









/**
 * @title Contract for the Eternal gaging platform
 * @author Nobody (me)
 * @notice The Eternal contract holds all user-data and gage logic.
 */
contract EternalOffering {

/////–––««« Variables: Events, Interfaces and Addresses »»»––––\\\\\

    // Signals the deployment of a new gage
    event NewGage(uint256 id, address indexed gageAddress);

    // The Joe router interface
    IJoeRouter02 public immutable joeRouter;
    // The Joe factory interface
    IJoeFactory public immutable joeFactory;
    // The Eternal token interface
    IERC20 public immutable eternal;
    // The Eternal storage interface
    IEternalStorage public immutable eternalStorage;
    // The Eternal treasury interface
    IEternalTreasury public immutable eternalTreasury;

    // The address of the ETRNL-USDCe pair
    address public immutable usdcePair;
    // The address of the ETRNL-AVAX pair
    address public immutable avaxPair;

/////–––««« Variables: Mappings »»»––––\\\\\

    // Keeps track of the respective gage tied to any given ID
    mapping (uint256 => address) private gages;
    // Keeps track of whether a user is in a loyalty gage or has provided liquidity for this offering
    mapping (address => mapping (address => bool)) private participated;
    // Keeps track of the amount of ETRNL the user has used in liquidity provision
    mapping (address => uint256) private liquidityOffered;
    // Keeps track of the amount of ETRNL the user has deposited
    mapping (address => uint256) private liquidityDeposited;

/////–––««« Variables: Constants, immutables and factors »»»––––\\\\\

    // The timestamp at which this contract will cease to offer
    uint256 private offeringEnds;
    // The holding time constant used in the percent change condition calculation (decided by the Eternal Fund) (x 10 ** 6)
    uint256 public constant TIME_FACTOR = 6 * (10 ** 6);
    // The average amount of time that users provide liquidity for
    uint256 public constant TIME_CONSTANT = 15;
    // The minimum token value estimate of transactions in 24h
    uint256 public constant ALPHA = 10 ** 7 * (10 ** 18);
    // The number of ETRNL allocated
    uint256 public constant LIMIT = 4207500 * (10 ** 21);
    // The USDCe address
    address public constant USDCe = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;

/////–––««« Variables: Gage/Liquidity bookkeeping »»»––––\\\\\

    // Keeps track of the latest Gage ID
    uint256 private lastId;
    // The total amount of ETRNL needed for current active gages
    uint256 private totalETRNLForGages;
    // The total number of ETRNL dispensed in this offering thus far
    uint256 private totalETRNLOffered;
    // The total number of USDCe-ETRNL lp tokens acquired
    uint256 private totalLpUSDCe;
    // The total number of AVAX-ETRNL lp tokens acquired
    uint256 private totalLpAVAX;

    // Allows contract to receive AVAX tokens
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

/////–––««« Constructor »»»––––\\\\\

    constructor (address _storage, address _eternal, address _treasury) {
        // Set the initial Eternal storage and token interfaces
        IEternalStorage _eternalStorage = IEternalStorage(_storage);
        eternalStorage = _eternalStorage;
        eternal = IERC20(_eternal);

        // Initialize the Trader Joe router and factory
        IJoeRouter02 _joeRouter = IJoeRouter02(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        IJoeFactory _joeFactory = IJoeFactory(_joeRouter.factory());
        joeRouter = _joeRouter;
        joeFactory = _joeFactory;

        // Create the pairs
        address _avaxPair = _joeFactory.createPair(_eternal, _joeRouter.WAVAX());
        address _usdcePair = _joeFactory.createPair(_eternal, USDCe);
        avaxPair = _avaxPair;
        usdcePair = _usdcePair;
        
        eternalTreasury = IEternalTreasury(_treasury);
    }

    function initialize() external {
        // Exclude the pairs from rewards
        bytes32 avaxExcluded = keccak256(abi.encodePacked("isExcludedFromRewards", avaxPair));
        bytes32 usdceExcluded = keccak256(abi.encodePacked("isExcludedFromRewards", usdcePair));
        bytes32 token = keccak256((abi.encodePacked(address(eternal))));
        bytes32 excludedAddresses = keccak256(abi.encodePacked("excludedAddresses"));
        if (!eternalStorage.getBool(token, avaxExcluded)) {
            eternalStorage.setBool(token, avaxExcluded, true);
            eternalStorage.setBool(token, usdceExcluded, true);
            eternalStorage.setAddressArrayValue(excludedAddresses, 0, avaxPair);
            eternalStorage.setAddressArrayValue(excludedAddresses, 0, usdcePair);
            offeringEnds = block.timestamp + 1 days;
        }
    }

/////–––««« Variable state-inspection functions »»»––––\\\\\

    /**
     * @notice Computes the equivalent of an asset to an other asset and the minimum amount of the two needed to provide liquidity.
     * @param asset The first specified asset, which we want to convert 
     * @param otherAsset The other specified asset
     * @param amountAsset The amount of the first specified asset
     * @param uncertainty The minimum loss to deduct from each minimum in case of price changes
     * @return minOtherAsset The minimum amount of otherAsset needed to provide liquidity (not given if uncertainty = 0)
     * @return minAsset The minimum amount of Asset needed to provide liquidity (not given if uncertainty = 0)
     * @return amountOtherAsset The equivalent in otherAsset of the given amount of asset
     */
    function _computeMinAmounts(address asset, address otherAsset, uint256 amountAsset, uint256 uncertainty) private view returns (uint256 minOtherAsset, uint256 minAsset, uint256 amountOtherAsset) {
        // Get the reserve ratios for the Asset-otherAsset pair
        (uint256 reserveA, uint256 reserveB,) = IJoePair(joeFactory.getPair(asset, otherAsset)).getReserves();
        (uint256 reserveAsset, uint256 reserveOtherAsset) = asset < otherAsset ? (reserveA, reserveB) : (reserveB, reserveA);

        // Determine a reasonable minimum amount of asset and otherAsset based on current reserves (with a tolerance =  1 / uncertainty)
        amountOtherAsset = joeRouter.quote(amountAsset, reserveAsset, reserveOtherAsset);
        if (uncertainty != 0) {
            minAsset = joeRouter.quote(amountOtherAsset, reserveOtherAsset, reserveAsset);
            minAsset -= minAsset / uncertainty;
            minOtherAsset = amountOtherAsset - (amountOtherAsset / uncertainty);
        }
    }

    /**
     * @notice View the total ETRNL offered in this IGO.
     * @return uint256 The total ETRNL distributed in this offering
     */
    function viewTotalETRNLOffered() external view returns (uint256) {
        return totalETRNLOffered;
    }

    /**
     * @notice View the total number of USDCe-ETRNL and AVAX-ETRNL lp tokens earned in this IGO.
     * @return uint256 The total number of lp tokens for the USDCe-ETRNl pair in this contract
     * @return uint256 The total number of lp tokens for the AVAX-ETRNL pair in this contract
     */
    function viewTotalLp() external view returns (uint256, uint256) {
        return (totalLpUSDCe, totalLpAVAX);
    }

    /**
     * @notice View the amount of ETRNL a given user has been offered in total.
     * @param user The specified user
     * @return uint256 The total amount of ETRNL offered for the user
     */
    function viewLiquidityOffered(address user) external view returns (uint256) {
        return liquidityOffered[user];
    }

    /**
     * @notice View the amount of ETRNL a given user has deposited (through provideLiquidity)
     * @param user The specified user
     * @return uint256 The total amount of ETRNL that has been deposited (but not gaged)
     */
    function viewLiquidityDeposited(address user) external view returns (uint256) {
        return liquidityDeposited[user];
    }

    /**
     * @notice View the address of a given loyalty gage.
     * @param id The id of the specified gage
     * @return address The address of the loyalty gage for this id
     */
    function viewGage(uint256 id) external view returns (address) {
        return gages[id];
    }

    /**
     * @notice View the current risk percentage for loyalty gages.
     * @return risk The percentage which the treasury takes if the loyalty gage closes in its favor
     */
    function viewRisk() public view returns (uint256 risk) {
        risk = totalETRNLOffered < LIMIT / 4 ? 3100 : (totalETRNLOffered < LIMIT / 2 ? 2600 : (totalETRNLOffered < LIMIT * 3 / 4 ? 2100 : 1600));
    }

    /**
     * @notice Evaluate whether the individual limit is reached for a given user and amount of ETRNL.
     * @return bool Whether transacting this amount of ETRNL respects the IGO limit for this user
     */
    function checkIndividualLimit(uint256 amountETRNL, address user) public view returns (bool) {
        return amountETRNL + liquidityOffered[user] <= (10 ** 7) * (10 ** 18);
    }

    /**
     * @notice Evaluate whether the global IGO limit is reached for a given amount of ETRNL
     * @return bool Whether there is enough ETRNL left to allow this IGO transaction
     */
    function checkGlobalLimit(uint256 amountETRNL) public view returns (bool) {
        return totalETRNLOffered + 2 * amountETRNL <= LIMIT;
    }
    
/////–––««« Gage-logic functions »»»––––\\\\\

    /**
     * @notice Provides liquidity to a given ETRNL/Asset pair
     * @param asset The asset in the ETRNL/Asset pair
     * @param amountETRNL The amount of ETRNL to add if we provide liquidity to the ETRNL/AVAX pair
     * @param minETRNL The min amount of ETRNL to be used in this operation
     * @param minAsset The min amount of the Asset to be used in this operation
     */
    function _provide(address asset, uint256 amount, uint256 amountETRNL, uint256 minETRNL, uint256 minAsset) private returns (uint256 providedETRNL, uint256 providedAsset) {
        uint256 liquidity;
        if (asset == joeRouter.WAVAX()) {
            (providedETRNL, providedAsset, liquidity) = joeRouter.addLiquidityAVAX{value: msg.value}(address(eternal), amountETRNL, minETRNL, minAsset, address(this), block.timestamp);
            totalLpAVAX += liquidity;
        } else {
            require(IERC20(asset).approve(address(joeRouter), amountETRNL), "Approve failed");
            (providedETRNL, providedAsset, liquidity) = joeRouter.addLiquidity(address(eternal), asset, amountETRNL, amount, minETRNL, minAsset, address(this), block.timestamp);
            totalLpUSDCe += liquidity;
        }
    }

    /**
     * @notice Creates an ETRNL loyalty gage contract for a given user and amount.
     * @param amount The amount of the asset being deposited in the loyalty gage by the receiver
     * @param asset The address of the asset being deposited in the loyalty gage by the receiver
     *
     * Requirements:
     * 
     * - The offering must be ongoing
     * - Only USDCe or AVAX loyalty gages are offered
     * - There can not have been more than 4 250 000 000 ETRNL offered in total
     * - A user can only participate in a maximum of one loyalty gage per asset
     * - A user can not send money to gages/provide liquidity for more than 10 000 000 ETRNL 
     * - The sum of the new amount provided and the previous amounts provided by a user can not exceed the equivalent of 10 000 000 ETRNL
     */
    function initiateEternalLoyaltyGage(uint256 amount, address asset) external payable {
        // Checks
        require(block.timestamp < offeringEnds, "Offering is over");
        require(asset == USDCe || (asset == joeRouter.WAVAX() && msg.value == amount), "Only USDCe or AVAX");
        require(!participated[msg.sender][asset], "User gage limit reached");

        // Compute the minimum amounts needed to provide liquidity and the equivalent of the asset in ETRNL
        (uint256 minETRNL, uint256 minAsset, uint256 amountETRNL) = _computeMinAmounts(asset, address(eternal), amount, 100);
        // Calculate risk
        uint256 rRisk = viewRisk();
        require(checkIndividualLimit(amountETRNL + (2 * amountETRNL * (rRisk - 100) / (10 ** 4)), msg.sender), "Amount exceeds the user limit");
        require(checkGlobalLimit(amountETRNL + (amountETRNL * (rRisk - 100) / (10 ** 4))), "ETRNL offering limit is reached");

        // Compute the percent change condition
        uint256 percent = 500 * ALPHA * TIME_CONSTANT * TIME_FACTOR / eternal.totalSupply();

        // Incremement the lastId tracker and increase the total ETRNL count
        lastId += 1;
        participated[msg.sender][asset] = true;

        // Deploy a new Gage
        LoyaltyGage newGage = new LoyaltyGage(lastId, percent, 2, false, address(this), msg.sender, address(eternalStorage));
        emit NewGage(lastId, address(newGage));
        gages[lastId] = address(newGage);

        //Transfer the deposit
        if (msg.value == 0) {
            require(IERC20(asset).transferFrom(msg.sender, address(this), amount), "Failed to deposit asset");
        }

        // Add liquidity to the ETRNL/Asset pair
        require(eternal.approve(address(joeRouter), amountETRNL), "Approve failed");
        (uint256 providedETRNL, uint256 providedAsset) = _provide(asset, amount, amountETRNL, minETRNL, minAsset);
        // Calculate the difference in asset given vs asset provided
        providedETRNL += (amount - providedAsset) * providedETRNL / amount;

        // Update the offering variables
        liquidityOffered[msg.sender] += providedETRNL + (2 * providedETRNL * (rRisk - 100) / (10 ** 4));
        totalETRNLOffered += 2 * (providedETRNL + (providedETRNL * (rRisk - 100) / (10 ** 4)));
        totalETRNLForGages += providedETRNL + (providedETRNL * (rRisk - 100) / (10 ** 4));

        // Initialize the loyalty gage and transfer the user's instant reward
        newGage.initialize(asset, address(eternal), amount, providedETRNL, rRisk, rRisk - 100);
        require(eternal.transfer(msg.sender, providedETRNL * (rRisk - 100) / (10 ** 4)), "Failed to transfer bonus");
    }

    /**
     * @notice Settles a given loyalty gage closed by a given receiver.
     * @param receiver The specified receiver 
     * @param id The specified id of the gage
     * @param winner Whether the gage closed in favour of the receiver
     *
     * Requirements:
     * 
     * - Only callable by a loyalty gage
     */
    function settleGage(address receiver, uint256 id, bool winner) external {
        // Checks
        address _gage = gages[id];
        require(msg.sender == _gage, "msg.sender must be the gage");

        // Load all gage data
        ILoyaltyGage gage = ILoyaltyGage(_gage);
        (,, uint256 rRisk) = gage.viewUserData(receiver);
        (,uint256 dAmount, uint256 dRisk) = gage.viewUserData(address(this));

        // Compute and transfer the net gage deposit due to the receiver
        if (winner) {
            dAmount += dAmount * dRisk / (10 ** 4);
        } else {
            dAmount -= dAmount * rRisk / (10 ** 4);
        }
        totalETRNLForGages -= dAmount * rRisk / (10 ** 4);
        require(eternal.transfer(receiver, dAmount), "Failed to transfer ETRNL");
    }

/////–––««« Liquidity Provision functions »»»––––\\\\\

    /**
     * @notice Provides liquidity to either the USDCe-ETRNL or AVAX-ETRNL pairs and sends ETRNL the msg.sender.
     * @param amount The amount of the asset being provided
     * @param asset The address of the asset being provided
     *
     * Requirements:
     * 
     * - The offering must be ongoing
     * - Only USDCe or AVAX can be used in providing liquidity
     * - There can not have been more than 4 250 000 000 ETRNL offered in total
     * - A user can not send money to gages/provide liquidity for more than 10 000 000 ETRNL 
     * - The sum of the new amount provided and the previous amounts provided by a user can not exceed the equivalent of 10 000 000 ETRNL
     */
    function provideLiquidity(uint256 amount, address asset) external payable {
        // Checks
        require(block.timestamp < offeringEnds, "Offering is over");
        require(asset == USDCe || asset == joeRouter.WAVAX(), "Only USDCe or AVAX");

        // Compute the minimum amounts needed to provide liquidity and the equivalent of the asset in ETRNL
        (uint256 minETRNL, uint256 minAsset, uint256 amountETRNL) = _computeMinAmounts(asset, address(eternal), amount, 200);
        require(checkIndividualLimit(amountETRNL, msg.sender), "Amount exceeds the user limit");
        require(checkGlobalLimit(amountETRNL), "ETRNL offering limit is reached");

        // Transfer user's funds to this contract if it's not already done
        if (msg.value == 0) {
            require(IERC20(asset).transferFrom(msg.sender, address(this), amount), "Failed to deposit funds");
        }

        // Add liquidity to the ETRNL/Asset pair
        require(eternal.approve(address(joeRouter), amountETRNL), "Approve failed");
        (uint256 providedETRNL, uint256 providedAsset) = _provide(asset, amount, amountETRNL, minETRNL, minAsset);

        // Update the offering variables
        totalETRNLOffered += providedETRNL;
        // Calculate and add the difference in asset given vs asset provided
        providedETRNL += (amount - providedAsset) * providedETRNL / amount;
        // Update the offering variables
        liquidityOffered[msg.sender] += providedETRNL;
        liquidityDeposited[msg.sender] += providedETRNL;
        totalETRNLOffered += providedETRNL;

        // Transfer ETRNL to the user
        require(eternal.transfer(msg.sender, providedETRNL), "ETRNL transfer failed");
    }

/////–––««« Post-Offering functions »»»––––\\\\\

    /**
     * @notice Transfers all lp tokens, leftover ETRNL and any dust present in this contract to the Eternal Treasury.
     * 
     * Requirements:
     *
     * - Either the time limit or ETRNL limit must be met
     */
    function sendLPToTreasury() external {
        // Checks
        require(totalETRNLOffered == LIMIT || offeringEnds < block.timestamp, "Offering not over yet");
        bytes32 treasury = keccak256(abi.encodePacked(address(eternalTreasury)));
        uint256 usdceBal = IERC20(USDCe).balanceOf(address(this));
        uint256 etrnlBal = eternal.balanceOf(address(this));
        uint256 avaxBal = address(this).balance;
        // Send the USDCe and AVAX balance of this contract to the Eternal Treasury if there is any dust leftover
        if (usdceBal > 0) {
            require(IERC20(USDCe).transfer(address(eternalTreasury), usdceBal), "USDCe Transfer failed");
        }
        if (avaxBal > 0) {
            (bool success,) = payable(address(eternalTreasury)).call{value: avaxBal}("");
            require(success, "AVAX transfer failed");
        }

        // Send any leftover ETRNL from this offering to the Eternal Treasury
        if (etrnlBal > totalETRNLForGages) {
            uint256 leftoverETRNL = etrnlBal - totalETRNLForGages;
            eternalTreasury.updateReserves(address(eternalTreasury), leftoverETRNL, eternalTreasury.convertToReserve(leftoverETRNL), true);
            require(eternal.transfer(address(eternalTreasury), leftoverETRNL), "ETRNL transfer failed");
        }

        // Send the lp tokens earned from this offering to the Eternal Treasury
        bytes32 usdceLiquidity = keccak256(abi.encodePacked("liquidityProvided", address(eternalTreasury), USDCe));
        bytes32 avaxLiquidity = keccak256(abi.encodePacked("liquidityProvided", address(eternalTreasury), joeRouter.WAVAX()));
        eternalStorage.setUint(treasury, usdceLiquidity, totalLpUSDCe);
        eternalStorage.setUint(treasury, avaxLiquidity, totalLpAVAX);
        require(IERC20(avaxPair).transfer(address(eternalTreasury), totalLpAVAX), "Failed to transfer AVAX lp");
        require(IERC20(usdcePair).transfer(address(eternalTreasury), totalLpUSDCe), "Failed to transfer USDCe lp");
    }
}