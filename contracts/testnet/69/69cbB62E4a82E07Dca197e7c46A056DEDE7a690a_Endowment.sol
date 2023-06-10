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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

import "./IDealStruct.sol";

interface IDealClient is IDealStruct {
    // struct DealRequest {
    //     bytes piece_cid;
    //     uint64 piece_size;
    //     bool verified_deal;
    //     string label;
    //     int64 start_epoch;
    //     int64 end_epoch;
    //     uint256 storage_price_per_epoch;
    //     uint256 provider_collateral;
    //     uint256 client_collateral;
    //     uint64 extra_params_version;
    //     ExtraParamsV1 extra_params;
    // }

    // // Extra parameters associated with the deal request. These are off-protocol flags that
    // // the storage provider will need.
    // struct ExtraParamsV1 {
    //     string location_ref;
    //     uint64 car_size;
    //     bool skip_ipni_announce;
    //     bool remove_unsealed_copy;
    // }

    // struct ProviderSet {
    //     bytes provider;
    //     bool valid;
    // }

    // struct RequestId {
    //     bytes32 requestId; // requestId is randomly generated
    //     bool valid;
    // }

    // /// @notice status of deal
    // enum Status {
    //     None,
    //     RequestSubmitted,
    //     DealPublished,
    //     DealActivated,
    //     DealTerminated
    // }

    // /**
    //  * @notice emitted when new deal proposal is created
    //  */
    // event DealProposalCreate(bytes32 indexed id, uint64 size, bool indexed verified, uint256 price);

    // event BalanceAdded(uint256 amount);

    function makeDealProposal(DealRequest calldata deal) external returns (bytes32);

    function addBalance(uint256 value) external;

    function withdrawBalance(address client, uint256 value) external returns (uint);

    function getDealId(bytes calldata cid) external view returns (uint64);

    function getPieceStatus(bytes calldata cid) external view returns (Status);

    function getProviderSet(bytes calldata cid) external view returns (ProviderSet memory);

    function getProposalIdSet(bytes calldata cid) external view returns (RequestId memory);

    function dealsLength() external view returns (uint256);

    function getDealByIndex(uint256 index) external view returns (DealRequest memory);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

interface IDealStruct {
    struct DealRequest {
        bytes piece_cid;
        uint64 piece_size;
        bool verified_deal;
        string label;
        int64 start_epoch;
        int64 end_epoch;
        uint256 storage_price_per_epoch;
        uint256 provider_collateral;
        uint256 client_collateral;
        uint64 extra_params_version;
        ExtraParamsV1 extra_params;
    }

    // Extra parameters associated with the deal request. These are off-protocol flags that
    // the storage provider will need.
    struct ExtraParamsV1 {
        string location_ref;
        uint64 car_size;
        bool skip_ipni_announce;
        bool remove_unsealed_copy;
    }

    struct ProviderSet {
        bytes provider;
        bool valid;
    }

    struct RequestId {
        bytes32 requestId; // requestId is randomly generated
        bool valid;
    }

    /// @notice status of deal
    enum Status {
        None,
        RequestSubmitted,
        DealPublished,
        DealActivated,
        DealTerminated
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IEndowment.sol";
import "./IEvents.sol";
import "../../Deal/IDealClient.sol";

error ZERO_ADDRESS();
error AMOUNT_CANT_BE_ZERO();
error ONLY_ONWER_CAN_CALL();
error TOKEN_TRANSFER_FAILURE();

contract Endowment is IEvents {
    /// @notice Address of the stable coin or inbound token or underlaying token
    address private owner;

    /**
     * @notice modifier to check that only the owner can call the function
     */
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert ONLY_ONWER_CAN_CALL();
        }
        _;
    }

    /**
     * @notice modifier to check that the input amount cannot be zero.
     * @param _amount Amount to check
     */
    modifier notZeroAmount(uint _amount) {
        if (_amount == 0) {
            revert AMOUNT_CANT_BE_ZERO();
        }
        _;
    }

    /**
     * @notice modifier to check that the input address can't be a zero address
     * @param _address Address to check
     */
    modifier notZeroAddress(address _address) {
        if (_address == address(0)) {
            revert ZERO_ADDRESS();
        }
        _;
    }

    /**
     * @notice constructor to set the address of the owner
     * @param _owner address of the owner
     */
    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * @notice function to receive funds from the user
     * @param _amount Amount to deposit in aave
     */
    function receiveFromUser(uint _amount, address _token) public notZeroAmount(_amount) {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        emit FundRecived(_token, msg.sender, _amount);
    }

    /**
     * @notice function to send tokens to selected Defi Pool
     * @param _token address of the token
     * @param _pool address of the defi Pool
     * @param _amount amount of tokens
     */
    function sendToDefi(address _token, address _pool, uint _amount) public {
        // IEndowment pool = IEndowment(_pool);
        // pool.receiveFromUser(_amount);
        bool success = IERC20(_token).transfer(_pool, _amount);
        if (!success) {
            revert TOKEN_TRANSFER_FAILURE();
        }
        IEndowment pool = IEndowment(_pool);
        // pool.receiveFromUser(_amount);
        pool.balance(_amount);
    }

    /**
     * @notice function to deposit tokens into a selected DeFi strategy and start generating yield.
     * @param _pool address of the defi Pool
     * @param _amount amount of tokens
     */
    function depositToDefi(address _pool, uint _amount) public {
        // ExternalContract externalContract = ExternalContract(externalContractAddress);
        IEndowment pool = IEndowment(_pool);
        pool.deposit(_amount);
    }

    /**
     * @notice function to withdraw tokens from a selected DeFi strategy and deposit them into DeFi pool.
     * @param _pool address of the defi Pool
     * @param _amount amount of tokens
     */
    function withdrawFromDefi(address _pool, uint _amount) public {
        // ExternalContract externalContract = ExternalContract(externalContractAddress);
        IEndowment pool = IEndowment(_pool);
        pool.withdraw(_amount);
    }

    /**
     * @notice function to transfer tokens from the DeFi pool to any designated receiver.
     * @param _pool address of the defi Pool
     * @param _amount amount of tokens
     * @param _receiver address of the receiver
     */
    function transferFromDefi(address _pool, uint _amount, address _receiver) public onlyOwner {
        // ExternalContract externalContract = ExternalContract(externalContractAddress);
        IEndowment pool = IEndowment(_pool);
        pool.transferTo(_amount, _receiver);
    }

    /**
     * @notice This function is designed to fund the built-in storage market actor's escrow using funds from the dealClient contract's own balance.
     * @dev dealClient contract should have more balance than the value 
     * @param _value amount of tokens
     * @param _dealClient address of the DealClient contract
     */
    function transferToDeal(uint256 _value, address _dealClient) external {
        IDealClient dealClient = IDealClient(_dealClient);
        dealClient.addBalance(_value);
        emit BalanceAdded(_value);
    }

    /**
     * @notice function to transfer funds from the endowment pool to any external contract or wallet, mainly to the "deal creation" contract, for the purpose of creating a deal.
     * @param _amount function to transfer funds from the endowment pool and to any receiver
     * @param _receiver address of the receiver
     */
    function transferTo(uint _amount, address _receiver, address _token) external onlyOwner {
        bool success = IERC20(_token).transfer(_receiver, _amount);
        if (!success) {
            revert TOKEN_TRANSFER_FAILURE();
        }
        emit TransferTo(_receiver, _amount);
    }

    ////////         Getter Functions              ///////
    /**
     * @notice function to get the address of the endowment pool
     * @param _token address of the token
     */
    function getContractBalance(address _token) public view returns (uint) {
        return IERC20(_token).balanceOf(address(this));
    }

    /**
     * @notice function to get the address of the endowment pool
     * @param _token address of the token
     */
    function getPoolBalance(address _token, address _pool) public view returns (uint) {
        return IERC20(_token).balanceOf(_pool);
    }

    /**
     * @notice function to get Vault Token balance of the smart contract
     * @param _pool address of the pool
     */
    function getVaultBalance(address _pool) public view returns (uint) {
        IEndowment pool = IEndowment(_pool);
        return pool.getUserVaultBalance(address(this));
    }

    /**
     * @notice function to get the Fil balance of the contract
     */
    function getFilBalance() public view returns (uint) {
        return address(this).balance;
    }

    /**
     * @notice receive() function is called to receive Fil if msg.data is empty
     */
    receive() external payable {
        emit RecievedFil(msg.sender, msg.value, "");
    }

    /**
     * @notice fallback() function is called to receive Fil if msg.data is NOT empty.
     */
    fallback() external payable {
        emit RecievedFil(msg.sender, msg.value, msg.data);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

interface IEndowment {
    function receiveFromUser(uint amount) external;

    function deposit(uint amount) external;

    function withdraw(uint amount) external;

    function transferTo(uint amount, address receiver) external;

    function getUserVaultBalance(address _user) external view returns (uint);

    function balance(uint _amount) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

interface IEvents {
    event FundRecived(address indexed token, address sender, uint amount);

    event DepositToDefi(address indexed lendingPool, address indexed token, uint amount);

    event WithdrawFromDeFi(address indexed token, uint amount);

    event TransferTo(address indexed receiver, uint amount);

    event BalanceAdded(uint256 amount);

    /**
     * @notice event emitted when ether is received.
     * @param sender address of the sender
     * @param amount amount of ether received
     * @param data The data that was sent with the transaction
     */
    event RecievedFil(address indexed sender, uint amount, bytes data);
}