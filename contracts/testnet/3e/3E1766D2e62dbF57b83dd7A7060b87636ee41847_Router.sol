// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../interfaces/IERC677.sol";
import "../lotteryGame/Constants.sol";

/**
 * @title Router contract
 * @author Applicature
 * @dev Contract for register AdditionalLottery contract as Keeper to track is game started and get winners
 */
contract Router {
    /// @notice registered additional lottery info
    /// @param lotteryRegisteredId getted id for registered additional lottery
    /// @param lotteryOwner owner of the additional lottery
    struct LotteriesInfo {
        uint256 lotteryRegisteredId;
        address lotteryOwner;
    }

    /// @notice Emit when additional lottery registered as a keeper
    /// @param name string of the upkeep to be registered
    /// @param encryptedEmail email address of upkeep contact
    /// @param lottery address to perform upkeep on
    /// @param gasLimit amount of gas to provide the target contract when performing upkeep
    /// @param adminRouter address to cancel upkeep and withdraw remaining funds
    /// @param checkData data passed to the contract when checking for upkeep
    /// @param amount quantity of LINK upkeep is funded with (specified in Juels)
    /// @param source application sending this request
    event Registered(
        string name,
        bytes encryptedEmail,
        address indexed lottery,
        uint32 gasLimit,
        address indexed adminRouter,
        bytes checkData,
        uint96 amount,
        uint8 source
    );

    /// @notice minimal gas limit is needed to register the additional lottery as a keeper
    uint96 private constant MIN_GAS_LIMIT = 2300;
    /// @notice LINK token address
    IERC677 public immutable linkToken;
    /// @notice UpkeepRegistration contract address
    address public immutable upkeepRegistration;
    /// @notice KeeperRegistry contrct addressа
    address public immutable keeperRegistry;
    // id - address of the lottery => value
    mapping(address => LotteriesInfo) public lotteriesOwners;

    constructor() {
        linkToken = IERC677(LINK_TOKEN);
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

        lotteriesOwners[lottery].lotteryOwner = msg.sender;

        (bool success, bytes memory returnData) = keeperRegistry.call(
            abi.encodeWithSignature("getUpkeepCount()")
        );
        require(success, "INVALID_CALL_GET");

        lotteriesOwners[lottery].lotteryRegisteredId = abi.decode(
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

        emit Registered(
            name,
            encryptedEmail,
            lottery,
            gasLimit,
            address(this),
            checkData,
            amount,
            source
        );
    }

    /// @notice delete the additional lottaery from chainlink keepers tracking
    /// @param lottery address of the additional lottery
    function cancelKeperAdditionalLottery(address lottery) external {
        (bool success, bytes memory returnData) = keeperRegistry.call(
            abi.encodeWithSelector(
                bytes4(keccak256("cancelUpkeep(uint256)")),
                lotteriesOwners[lottery].lotteryRegisteredId
            )
        );
        require(success, "INVALID_CALL_CANCEL");
    }

    /// @notice withdraw unused LINK tokens from keepers back to the owner of the additional lottery
    /// @param lottery address of the additional lottery
    function withdrawTokens(address lottery) external {
        //withdraw tokens
        (bool success, bytes memory returnData) = keeperRegistry.call(
            abi.encodeWithSelector(
                bytes4(keccak256("withdrawFunds(uint256,address)")),
                lotteriesOwners[lottery].lotteryRegisteredId,
                lotteriesOwners[lottery].lotteryOwner
            )
        );
        require(success, "INVALID_CALL_WITHDRAW");
    }

    /// @notice pop up keeper with LINK tokens to continue tracking lottery
    /// @param lottery address of the additional lottery
    /// @param amount amount of LINK tokens
    function addFunds(address lottery, uint96 amount) external {
        linkToken.transferFrom(msg.sender, address(this), amount);
        linkToken.approve(keeperRegistry, amount);

        (bool success, bytes memory returnData) = keeperRegistry.call(
            abi.encodeWithSelector(
                bytes4(keccak256("addFunds(uint256,uint96)")),
                lotteriesOwners[lottery].lotteryRegisteredId,
                amount
            )
        );
        require(success, "INVALID_CALL_ADD_FUNDS");
    }
}

// SPDX-License-Identifier:MIT
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

/// @title IERC677 interface
/// @author Applicature
/// @dev interface for LINK tokens from ChainLinkKeepers to register CustomLotteryGame as a keeper
interface IERC677 is LinkTokenInterface {
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

uint256 constant WINNERS_LIMIT = 10;
uint256 constant BENEFICIARY_LIMIT = 100;
address constant VRF_COORDINATOR = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
address constant KEEPERS_REGISTRY = 0x409CF388DaB66275dA3e44005D182c12EeAa12A0;
address constant LINK_TOKEN = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
address constant UPKEEP_REGISTRATION = 0xb3532682f7905e06e746314F6b12C1e988B94aDB;
uint256 constant HUNDRED_PERCENT_WITH_PRECISONS = 10_000;
uint256 constant MIN_LINK_TOKENS_NEEDDED = 5_000_000_000_000_000_000;
uint256 constant DECIMALS = 10**18;
uint8 constant MIN_LINK = 5;

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