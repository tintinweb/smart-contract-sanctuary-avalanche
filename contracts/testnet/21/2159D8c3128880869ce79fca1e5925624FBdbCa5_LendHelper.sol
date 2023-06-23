// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.12;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.12;

import {DataTypes} from "./DataTypes.sol";

/**
 * @dev refer to https://github.com/aave/protocol-v2
 **/
interface ILendingPool {
  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;
  
  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

/// @dev refer to https://github.com/compound-finance/compound-protocol
interface CTokenInterface {
    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
}

interface CErc20Interface {
    /**
     * @notice Underlying asset for this CToken
     */
    function underlying() external returns (address);
    function redeem(uint redeemTokens) external returns (uint);
    function mint(uint mintAmount) external returns (uint);
}

interface CEtherInterface {
    function mint() external payable;
}

abstract contract CErc20 is CTokenInterface, CErc20Interface {
}

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface IPoolAddressesProvider {

    function wethAddress() external view returns(address);
    function aclManagerAddress() external view returns(address);
    function infinityTokenAddress() external view returns(address);
    function liquidationProtocolAddresses(uint64 protocolId) external view returns(address);
    function registerLiquidationProtocol(uint64 protocolId, address protocolAddress) external;
    function getInfinitySupportedTokens() external view returns (address[] memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "../dependencies/openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "../dependencies/aave-v2/ILendingPool.sol";
import "../dependencies/compound-v2/ICompound.sol";
import "../interfaces/IPoolAddressesProvider.sol";
import "../interfaces/IWETH.sol";
import "./TransferHelper.sol";

/**
 * @dev allow lending via either Aave or Compound or Aave and Compound together (but same input amount)
 */
library LendHelper {
	function serverLend(IPoolAddressesProvider poolAddressProvider, address _aaveLendingPoolAddress, address _cToken, address _underlyingAsset, uint256 _amount) external {
		if (_aaveLendingPoolAddress != address(0x0)) {
			TransferHelper.safeApprove(_underlyingAsset, _aaveLendingPoolAddress, _amount);
			ILendingPool(_aaveLendingPoolAddress).deposit(_underlyingAsset, _amount, address(this), 0);
		}
		if (_cToken != address(0x0)) {
			if (_underlyingAsset == poolAddressProvider.wethAddress()) {
				if (address(this).balance < _amount) {
					IWETH(poolAddressProvider.wethAddress()).withdraw(_amount);
				}
				CEtherInterface(_cToken).mint{value: _amount}();
			} else {
				TransferHelper.safeApprove(_underlyingAsset, _cToken, _amount);
				CErc20Interface(_cToken).mint(_amount);
			}
		}
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

library TransferHelper {
    function safeApprove( address token, address to, uint256 value ) public {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("approve(address,uint256)", to, value));
        require( success && (data.length == 0 || abi.decode(data, (bool))), "approve failed" );
    }

    function safeTransferFrom( address token, address from, address to, uint256 value ) public {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, value));
        require( success && (data.length == 0 || abi.decode(data, (bool))), "transferFrom failed" );
    }

    function safeTransfer( address token, address to, uint256 value ) public {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, value));
        require( success && (data.length == 0 || abi.decode(data, (bool))), "transfer failed" );
    }

    function safeTransferFromERC721( address token, address from, address to, uint256 tokenId ) public {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", from, to, tokenId));
        require( success && (data.length == 0 || abi.decode(data, (bool))), "ERC721 safeTransferFrom failed" );
    }

    function balanceOf( address token, address account ) public returns (uint256 balance){
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("balanceOf(address)", account));
        require(success,"balanceOf failed");
        balance = abi.decode(data, (uint256));
    }
}