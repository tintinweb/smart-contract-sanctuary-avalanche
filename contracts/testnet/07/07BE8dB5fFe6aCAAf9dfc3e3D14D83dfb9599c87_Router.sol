// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../interfaces/IERC677.sol";

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

    uint256 private constant DECIMALS = 10**18;
    /// @notice minimum LINk tokens are needed to register the additional lottery as a keeper
    uint8 private constant MIN_LINK = 5;
    /// @notice minimal gas limit is needed to register the additional lottery as a keeper
    uint96 private constant MIN_GAS_LIMIT = 2300;
    /// @notice LINK token address
    IERC677 public immutable linkToken;
    /// @notice UpkeepRegistration contract address
    address public upkeepRegistration;
    /// @notice KeeperRegistry contrct addressа
    address public keeperRegistry;
    // id - address of the lottery => value
    mapping(address => LotteriesInfo) public lotteriesOwners;

    constructor(
        address linkToken_,
        address upkeepRegistration_,
        address keeperRegistry_
    ) {
        require(
            linkToken_ != address(0) && upkeepRegistration_ != address(0),
            "ZERO_ADDRESS"
        );
        linkToken = IERC677(linkToken_);
        upkeepRegistration = upkeepRegistration_;
        keeperRegistry = keeperRegistry_;
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

        linkToken.transferFrom(msg.sender, address(this), amount);

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

    function addFunds(address lottery,uint96 amount) external {
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IERC677 interface
/// @author Applicature
/// @dev interface for LINK tokens from ChainLinkKeepers to register CustomLotteryGame as a keeper
interface IERC677 is IERC20 {
    /// @dev transfer token to a contract address with additional data if the recipient is a contact
    /// @param to the address to transfer to.
    /// @param value the amount to be transferred.
    /// @param data the extra data to be passed to the receiving contract.
    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT

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