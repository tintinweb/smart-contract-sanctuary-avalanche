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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IEndowment.sol";
import "./IEvents.sol";

error ZERO_ADDRESS();
error AMOUNT_CANT_BE_ZERO();
error ONLY_ONWER_CAN_CALL();
error TOKEN_TRANSFER_FAILURE();

contract Endowment is IEvents {
    /// @notice Address of the stable coin or inbound token or underlaying token
    // IERC20 public stableCoin;

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

    function sendToDefi(address _pool, uint _amount) public onlyOwner {
        // ExternalContract externalContract = ExternalContract(externalContractAddress);
        IEndowment pool = IEndowment(_pool);
        pool.receiveFromUser(_amount);
    }

    function depositToDefi(address _pool, uint _amount) public onlyOwner {
        // ExternalContract externalContract = ExternalContract(externalContractAddress);
        IEndowment pool = IEndowment(_pool);
        pool.deposit(_amount);
    }

    function withdrawFromDefi(address _pool, uint _amount) public onlyOwner {
        // ExternalContract externalContract = ExternalContract(externalContractAddress);
        IEndowment pool = IEndowment(_pool);
        pool.withdraw(_amount);
    }

    function transferFromDefi(address _pool, uint _amount, address _receiver) public onlyOwner {
        // ExternalContract externalContract = ExternalContract(externalContractAddress);
        IEndowment pool = IEndowment(_pool);
        pool.transferTo(_amount, _receiver);
    }

    /**
     * @notice function to transfer funds from the endowment pool to any external contract or wallet, mainly to the "deal creation" contract, for the purpose of creating a deal.
     * @param _amount function to transfer funds from the endowment pool and to any receiver
     * @param _receiver address of the receiver
     */
    function transferTo(uint _amount, address _receiver, address _token) external onlyOwner{
        bool success = IERC20(_token).transfer(msg.sender, _amount);
        if (!success) {
            revert TOKEN_TRANSFER_FAILURE();
        }
        emit TransferTo(_receiver, _amount);
    }

    /**
     * @notice function to get the address of the endowment pool
     * @param _token address of the token
     */
    function getBalance(address _token) public view returns (uint) {
        return IERC20(_token).balanceOf(address(this));
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

interface IEndowment {
    function receiveFromUser(uint amount) external;

    function deposit(uint amount) external;

    function withdraw(uint amount) external;

    function transferTo(uint amount, address receiver) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

interface IEvents {
    event FundRecived(address indexed token, address sender, uint amount);

    event DepositToDefi(address indexed lendingPool, address indexed token, uint amount);

    event WithdrawFromDeFi(address indexed token, uint amount);

    event TransferTo(address indexed receiver, uint amount);
}