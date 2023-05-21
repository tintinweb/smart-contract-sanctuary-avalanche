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

interface IAaveProtocolDataProvider {
    function getReserveTokensAddresses(address asset) external view returns (address, address, address);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

interface IAToken {
    /// @dev Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

interface ILendingPool {
    function deposit(address reserve, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    function withdraw(address asset, uint256 amount, address to) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

interface ILendingPoolV3 {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    function withdraw(address asset, uint256 amount, address to) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

interface IPoolAddressesProvider {
    function getPool() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

import "../aaveV3/IPoolAddressesProvider.sol";
import "../aaveV3/ILendingPoolV3.sol";
import "../aaveV2/ILendingPool.sol";
import "../aaveV2/IAaveProtocolDataProvider.sol";
import "../aaveV2/IAToken.sol";
import "./IYield.sol";
import "./IEvents.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error ZERO_ADDRESS();
error INVALID_LENDING_POOL_ADDRESS_PROVIDER();
error INVALID_DATA_PROVIDER();
error AMOUNT_CANT_BE_ZERO();
error TOKEN_TRANSFER_FAILURE();
error NOT_ENOUGH_AAVE_BALANCE();
error NOT_ENOUGH_STABLE_BALANCE();
error INVALID_STABLE_COIN();
error NOT_ENOUGH_AAVE_BALANCE_USER();

contract AaveYieldV3 is IYield, IEvents {
    /// @notice Aave referral code (still need to research on that)
    uint16 public constant REFERRAL_CODE = 0;

    /// @notice Aave instance we use to swap Inbound Token to interest bearing aUSDC
    IPoolAddressesProvider public immutable poolAddressesProvider;

    /// @notice Lending pool address
    ILendingPool public immutable lendingPool;

    /// @notice Address of the stable coin or inbound token or underlaying token
    IERC20 public immutable stableCoin;

    /// @notice Atoken address
    IAToken public immutable aToken;

    /// @notice AaveProtocolDataProvider address
    IAaveProtocolDataProvider public dataProvider;

    /**
     * @notice mapping to track the balance of the user in the defi
     */
    // mapping(address => uint) public balance;

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
     * @param _poolAddressesProvider A contract which is used as a registry on aave.
     * @param _stableCoin Stablecoin address
     * @param _dataProvider AaveProtocolDataProvider address
     */
    constructor(
        address _poolAddressesProvider,
        address _stableCoin,
        address _dataProvider
    ) notZeroAddress(_poolAddressesProvider) notZeroAddress(_dataProvider) {
        // if (address(_poolAddressesProvider) == address(0)) {
        //     revert INVALID_LENDING_POOL_ADDRESS_PROVIDER();
        // }

        // if (address(_dataProvider) == address(0)) {
        //     revert INVALID_DATA_PROVIDER();
        // }

        stableCoin = IERC20(_stableCoin);

        poolAddressesProvider = IPoolAddressesProvider(_poolAddressesProvider);

        dataProvider = IAaveProtocolDataProvider(_dataProvider);

        lendingPool = ILendingPool(IPoolAddressesProvider(_poolAddressesProvider).getPool());

        address aTokenAddress;
        (aTokenAddress, , ) = dataProvider.getReserveTokensAddresses(address(_stableCoin));
        aToken = IAToken(aTokenAddress);
    }

    // /**
    //  * @notice function to receive funds from the user
    //  * @param _amount Amount to deposit in aave
    //  */
    // function receiveFromUser(uint _amount) external notZeroAmount(_amount) {
    //     IERC20(stableCoin).transferFrom(msg.sender, address(this), _amount);
    // }

    function receiveFromUser(uint _amount) external {
        IERC20(stableCoin).approve(address(this), _amount); // ?
        IERC20(stableCoin).transferFrom(msg.sender, address(this), _amount);
        emit FundRecived(address(stableCoin), msg.sender, _amount);
    }

    // /**
    //  * @notice function to deposit STABLE COIN in AAVE
    //  * @param _amount Amount to deposit in aave.
    //  * @dev can remove _amount parameter and set msg.value instead
    //  */
    // function deposit(uint _amount) public notZeroAmount(_amount) {
    //     if (getContractStableBalance() < _amount) {
    //         revert NOT_ENOUGH_STABLE_BALANCE();
    //     }
    //     IERC20(stableCoin).approve(address(lendingPool), _amount);
    //     lendingPool.deposit(address(stableCoin), _amount, address(this), REFERRAL_CODE);
    // }

    function deposit(uint _amount) external {
        // IERC20(stableCoin).transferFrom(msg.sender, address(this), _amount);
        // if (getContractStableBalance() < _amount) {
        //     revert NOT_ENOUGH_STABLE_BALANCE();
        // }
        IERC20(stableCoin).approve(address(lendingPool), _amount);
        // lendingPool.deposit(address(stableCoin), _amount, address(this), REFERRAL_CODE);
        lendingPool.deposit(address(stableCoin), _amount, msg.sender, REFERRAL_CODE);
        emit DepositToDefi(address(lendingPool), address(stableCoin), _amount);
    }

    /**
     * @notice function to withdraw funds from the AAVE protocol and recieve it our endowment pool
     * @param _amount Amount to deposit from aave.
     */
    function withdraw(uint _amount) external {
        // if (aToken.balanceOf(address(this)) < _amount) {
        //     revert NOT_ENOUGH_AAVE_BALANCE();
        // }
        if (aToken.balanceOf(msg.sender) < _amount) {
            revert NOT_ENOUGH_AAVE_BALANCE_USER();
        }
        // withdraw the money from AAVE to our endowment pool
        // lendingPool.withdraw(address(stableCoin), _amount, address(this));
        lendingPool.withdraw(address(stableCoin), _amount, msg.sender);
        emit WithdrawFromDeFi(address(stableCoin), _amount);
    }

    /**
     * @notice function to transfer funds from the endowment pool and transfer it to any external contract or wallet.
     * @param _amount function to transfer funds from the endowment pool and to any receiver
     * @param _receiver address of the receiver
     */
    function transferTo(uint _amount, address _receiver) external {
        bool success = IERC20(stableCoin).transfer(msg.sender, _amount);
        if (!success) {
            revert TOKEN_TRANSFER_FAILURE();
        }
        emit TransferTo(_receiver, _amount);
    }

    /**
     * @notice Returns the total accumulated amount (i.e., principal + interest) stored in aave Intended for usage by external clients and in case of variable deposit pools.
     * @return Total accumulated amount.
     */
    function getTotalAmount() external view override returns (uint256) {
        return aToken.balanceOf(address(this));
    }

    /**
     * @notice Returns the total accumulated amount (i.e., principal + interest) stored in aave owned by the user.
     * @return Total accumulated amount.
     */
    function getUserVaultBalance(address _user) external view returns (uint) {
        return aToken.balanceOf(_user);
    }

    /**
     * @notice Returns the underlying stablecoin (deposit) address.
     * @return Underlying stablecoin address.
     */
    function getStableCoin() external view override returns (address) {
        return aToken.UNDERLYING_ASSET_ADDRESS();
    }

    /**
     * @notice function to get the stable coin balance of the user
     * @param _user address of the user
     */
    function getUserStableBalance(address _user) public view returns (uint) {
        return IERC20(stableCoin).balanceOf(_user);
    }

    /**
     * @notice function to get the stable coin balance of this smart contract
     */
    function getContractStableBalance() public view returns (uint) {
        return IERC20(stableCoin).balanceOf(address(this));
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

interface IEvents {
    event FundRecived(address indexed token, address sender, uint amount);

    event DepositToDefi(address indexed lendingPool, address indexed token, uint amount);

    event WithdrawFromDeFi(address indexed token, uint amount);

    event TransferTo(address indexed receiver, uint amount);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IYield {
    function getTotalAmount() external view returns (uint256);

    function getStableCoin() external view returns (address);
}