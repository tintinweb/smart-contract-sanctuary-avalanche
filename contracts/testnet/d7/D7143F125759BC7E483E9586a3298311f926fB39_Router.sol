// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "../Constants.sol";
import "../lotteryGame/ConvertAvax.sol";

/**
 * @title Router contract
 * @author Applicature
 * @dev Contract for register AdditionalLottery contract as Keeper to track is game started and get winners
 */
contract Router is ConvertAvax{
    /// @notice registered additional lottery info
    /// @param lotteryRegisteredId getted id for registered additional lottery
    /// @param subscriptionId subscription id for VRF
    /// @param lotteryOwner owner of the additional lottery
    struct LotteriesInfo {
        uint256 lotteryRegisteredId;
        uint64 subscriptionId;
        address lotteryOwner;
    }

    /// @notice Emit when additional lottery registered as a keeper
    /// @param name string of the upkeep to be registered
    /// @param encryptedEmail email address of upkeep contact
    /// @param lottery address to perform upkeep on
    /// @param keeperId subscription id for Keepers
    /// @param gasLimit amount of gas to provide the target contract when performing upkeep
    /// @param checkData data passed to the contract when checking for upkeep
    /// @param amount quantity of LINK upkeep is funded with (specified in Juels)
    /// @param source application sending this request
    event KeeperRegistered(
        string name,
        bytes encryptedEmail,
        address indexed lottery,
        uint256 indexed keeperId,
        uint32 gasLimit,
        bytes checkData,
        uint96 amount,
        uint8 source
    );

    /// @notice Emit when additional lottery registered as a VRF
    /// @param lottery address to perform VRF  on
    /// @param subscriptionId subscription id for VRF
    event VRFRegistered(
        address indexed lottery, 
        uint64 indexed subscriptionId
    );

    /// @notice minimal gas limit is needed to register the additional lottery as a keeper
    uint96 private constant MIN_GAS_LIMIT = 2300;
    /// @notice LINK token address
    LinkTokenInterface public immutable linkToken;
    /// @notice UpkeepRegistration contract address
    address public immutable upkeepRegistration;
    /// @notice KeeperRegistry contrct addressа
    address public immutable keeperRegistry;
    // id - address of the lottery => value
    mapping(address => LotteriesInfo) public registeredLotteries;
    mapping (address => uint64) public subscriptionId;

    constructor() ConvertAvax(LINK_TOKEN)  {
        linkToken = LinkTokenInterface(LINK_TOKEN);
        upkeepRegistration = UPKEEP_REGISTRATION;
        keeperRegistry = KEEPERS_REGISTRY;
    }

    /// @dev approve transfering tokens in LinkToken SC to Router SC before request keeper registration
    /// @param name string of the upkeep to be registered
    /// @param encryptedEmail email address of upkeep contact
    /// @param gasLimit amount of gas to provide the target contract when performing upkeep
    /// @param checkData data passed to the contract when checking for upkeep
    /// @param amount quantity of LINK upkeep is funded with (specified in Juels)
    /// @param source application sending this request
    /// @param lottery address to perform upkeep on
    function registerAdditionalLottery(
        string memory name,
        bytes memory encryptedEmail,
        uint32 gasLimit,
        bytes memory checkData,
        uint96 amount,
        uint8 source,
        address lottery
    ) external {
        require(gasLimit >= MIN_GAS_LIMIT, "LOW_GAS_LIMIT");
        require(amount >= MIN_LINK * DECIMALS, "LOW_AMOUNT");
        require(
            linkToken.balanceOf(address(this)) >= MIN_LINK * DECIMALS,
            "NOT_ENOUGHT_TOKENS"
        );

        registeredLotteries[lottery].lotteryOwner = msg.sender;

        (bool success, bytes memory returnData) = keeperRegistry.call(
            abi.encodeWithSignature("getUpkeepCount()")
        );
        require(success, "INVALID_CALL_GET");

        registeredLotteries[lottery].lotteryRegisteredId = abi.decode(
            returnData,
            (uint256)
        );

        // register as upkeep additional lottery
        linkToken.transferAndCall(
            upkeepRegistration,
            amount,
            abi.encodeWithSelector(
                bytes4(
                    keccak256(
                        "register(string,bytes,address,uint32,address,bytes,uint96,uint8)"
                    )
                ),
                name,
                encryptedEmail,
                lottery,
                gasLimit,
                address(this),
                checkData,
                amount,
                source
            )
        );

        emit KeeperRegistered(
            name,
            encryptedEmail,
            lottery,
            registeredLotteries[lottery].lotteryRegisteredId,
            gasLimit,
            checkData,
            amount,
            source
        );

        // register game for VRF work
        VRFCoordinatorV2Interface coordinator = VRFCoordinatorV2Interface(VRF_COORDINATOR);
        uint64 subId = coordinator.createSubscription();
        coordinator.addConsumer(
            subId,
            lottery
        );

        registeredLotteries[lottery].subscriptionId = subId;

        emit VRFRegistered(lottery, subId);
    }

    /// @notice delete the additional lottaery from chainlink keepers tracking
    /// @param lottery address of the additional lottery
    function cancelSubscription(address lottery) external {
        (bool success, ) = keeperRegistry.call(
            abi.encodeWithSelector(
                bytes4(keccak256("cancelUpkeep(uint256)")),
                registeredLotteries[lottery].lotteryRegisteredId
            )
        );
        require(success, "INVALID_CALL_CANCEL");
        VRFCoordinatorV2Interface(VRF_COORDINATOR)
            .cancelSubscription(registeredLotteries[lottery].subscriptionId,  registeredLotteries[lottery].lotteryOwner);
        registeredLotteries[lottery].subscriptionId = 0;
    }

    /// @notice withdraw unused LINK tokens from keepers back to the owner of the additional lottery
    /// @param lottery address of the additional lottery
    function withdrawKeepers(address lottery) external {
        //withdraw tokens
        (bool success, ) = keeperRegistry.call(
            abi.encodeWithSelector(
                bytes4(keccak256("withdrawFunds(uint256,address)")),
                registeredLotteries[lottery].lotteryRegisteredId,
                registeredLotteries[lottery].lotteryOwner
            )
        );
        require(success, "INVALID_CALL_WITHDRAW");
    }

    /// @notice withdraw unused LINK tokens from VRF back to the owner of the additional lottery
    /// @param lottery address of the additional lottery
    function withdrawVRF(address lottery) external {
        //withdraw tokens
        (bool success, ) = keeperRegistry.call(
            abi.encodeWithSelector(
                bytes4(keccak256("withdrawFunds(uint256,address)")),
                registeredLotteries[lottery].lotteryRegisteredId,
                registeredLotteries[lottery].lotteryOwner
            )
        );
        require(success, "INVALID_CALL_WITHDRAW");
    }

    /// @notice pop up keeper with LINK tokens to continue tracking lottery
    /// @param lottery address of the additional lottery
    /// @param amountKeepers amount of LINK tokens to pop up kepeers
    /// @param amountVRF amount of LINK tokens to pop up VRF
    function addFunds(address lottery, uint96 amountKeepers, uint256 amountVRF) external {
        uint256 amount = amountKeepers + amountVRF;
        linkToken.transferFrom(msg.sender, address(this), amount);
        linkToken.approve(keeperRegistry, amount);

        (bool success, ) = keeperRegistry.call(
            abi.encodeWithSelector(
                bytes4(keccak256("addFunds(uint256,uint96)")),
                registeredLotteries[lottery].lotteryRegisteredId,
                amountKeepers
            )
        );

        require(success, "INVALID_CALL_ADD_FUNDS");

        linkToken.transferAndCall(
            VRF_COORDINATOR,
            amountVRF,
            abi.encode(registeredLotteries[lottery].subscriptionId)
        );
    }

    function getSubscriptionId(address lottery) external view returns(uint64){
        return registeredLotteries[lottery].subscriptionId;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// chainlink
address constant VRF_COORDINATOR = 0x2eD832Ba664535e5886b75D64C46EB9a228C2610;
address constant KEEPERS_REGISTRY = 0xE16Df59B887e3Caa439E0b29B42bA2e7976FD8b2; //0x409CF388DaB66275dA3e44005D182c12EeAa12A0;
address constant LINK_TOKEN = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
address constant UPKEEP_REGISTRATION = 0xE16Df59B887e3Caa439E0b29B42bA2e7976FD8b2;//0xb3532682f7905e06e746314F6b12C1e988B94aDB;
//lottery
uint256 constant WINNERS_LIMIT = 10;
uint256 constant BENEFICIARY_LIMIT = 100;
uint256 constant HUNDRED_PERCENT_WITH_PRECISONS = 10_000;
uint256 constant FIFTY_PERCENT_WITH_PRECISONS = 5_000;
uint256 constant MIN_LINK_TOKENS_NEEDDED = 5 ether;
uint256 constant DECIMALS = 1 ether;
uint8 constant MIN_LINK = 5;
//convert avax<>link
address constant PANGOLIN_ROUTER = 0x3705aBF712ccD4fc56Ee76f0BD3009FD4013ad75;

error ZeroAddress();
error ZeroAmount();
error IncorrectLength();
error IncorrectPercentsSum();
error IncorrectPercentsValue();
error GameDeactivated();
error IncorrectTimelock();
error UnderLimit();
error GameNotReadyToStart();
error ParticipateAlready();
error InvalidParticipatee();
error LimitExeed();
error IsDeactivated();
error SubscriptionIsEmpty();
error SubscriptionIsNotEmpty();
error GameIsNotActive();
error GameIsStarted();
error UnderParticipanceLimit();
error InvalidEntryFee();
error InvalidCallerFee();
error InvalidTimelock();
error AnuthorizedCaller();
error InsufficientBalance();

string constant ERROR_INCORRECT_LENGTH = "0x1";
string constant ERROR_INCORRECT_PERCENTS_SUM = "0x2";
string constant ERROR_DEACTIVATED_GAME = "0x3";
string constant ERROR_CALLER_FEE_CANNOT_BE_MORE_100 = "0x4";
string constant ERROR_TIMELOCK_IN_DURATION_IS_ACTIVE = "0x5";
string constant ERROR_DATE_TIME_TIMELOCK_IS_ACTIVE = "0x6";
string constant ERROR_LIMIT_UNDER = "0x7";
string constant ERROR_INCORRECT_PERCENTS_LENGTH = "0x8";
string constant ERROR_NOT_READY_TO_START = "0x9";
string constant ERROR_NOT_ACTIVE_OR_STARTED = "0xa";
string constant ERROR_PARTICIPATE_ALREADY = "0xb";
string constant ERROR_INVALID_PARTICIPATE = "0xc";
string constant ERROR_LIMIT_EXEED = "0xd";
string constant ERROR_ALREADY_DEACTIVATED = "0xe";
string constant ERROR_GAME_STARTED = "0xf";
string constant ERROR_NO_SUBSCRIPTION = "0x10";
string constant ERROR_NOT_ACTIVE = "0x11";
string constant ERROR_ZERO_ADDRESS = "0x12";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/pangolin/IPangolinRouter.sol";
import "../Constants.sol";

contract ConvertAvax{
    IPangolinRouter private constant PANGOLIN = IPangolinRouter(PANGOLIN_ROUTER);
    address internal immutable LINK;
    address internal immutable WAVAX;

    event Swap(uint256 indexed amountIn, uint256 amountMin, address[] path);
    constructor(address link_){
        WAVAX = PANGOLIN.WAVAX();
        LINK = link_;
    }

    function _swapAvaxToLink(address to) internal {
        uint256 amountIn = msg.value;
        if (amountIn == 0){
            revert ZeroAmount();
        }
        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = LINK;
        uint256 amountOutMin = getAmountOutMin(path, amountIn);
        PANGOLIN.swapExactAVAXForTokens{value: amountIn}(amountOutMin, path, to, block.timestamp + 1 hours);
    }

    function swapAvaxToLink(address to) public payable {
        swapAvaxToLink(to);
    }

    function getAmountOutMin(address[] memory path_, uint256 amountIn_) private view returns (uint256) {        
        uint256[] memory amountOutMins = PANGOLIN.getAmountsOut(amountIn_, path_);
        return amountOutMins[path_.length - 1];  
    } 

}


/// WBTC = 0x5d870A421650C4f39aE3f5eCB10cBEEd36e6dF50
/// PartyROuter = 0x3705aBF712ccD4fc56Ee76f0BD3009FD4013ad75
/// PagolinRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPangolinRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountAVAX);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAXWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountAVAX);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactAVAX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapAVAXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountAVAX);
    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}