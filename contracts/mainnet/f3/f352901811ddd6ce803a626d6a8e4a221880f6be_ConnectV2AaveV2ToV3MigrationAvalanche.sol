//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { TokenInterface, AccountInterface } from "../../../common/interfaces.sol";
import "./interfaces.sol";
import "./helpers.sol";
import "./events.sol";

/**
 * @title Aave v2 to v3 import connector .
 * @dev  migrate aave V2 position to aave v3 position
 */
contract _AaveV2ToV3MigrationResolver is _AaveHelper {
	function _importAave(
		address userAccount,
		ImportInputData memory inputData,
		bool doImport
	) internal returns (string memory _eventName, bytes memory _eventParam) {
		if (doImport) {
			// check only when we are importing from user's address
			require(
				AccountInterface(address(this)).isAuth(userAccount),
				"user-account-not-auth"
			);
		}
		require(inputData.supplyTokens.length > 0, "0-length-not-allowed");

		ImportData memory data;

		AaveV2Interface aaveV2 = AaveV2Interface(
			aaveV2Provider.getLendingPool()
		);
		AaveV3Interface aaveV3 = AaveV3Interface(aaveV3Provider.getPool());

		data = getBorrowAmountsV2(userAccount, aaveV2, inputData, data);
		data = getSupplyAmountsV2(userAccount, inputData, data);

		//  payback borrowed amount;
		_PaybackStableV2(
			data._borrowTokens.length,
			aaveV2,
			data._borrowTokens,
			data.stableBorrowAmts,
			userAccount
		);
		_PaybackVariableV2(
			data._borrowTokens.length,
			aaveV2,
			data._borrowTokens,
			data.variableBorrowAmts,
			userAccount
		);

		if (doImport) {
			//  transfer atokens to this address;
			_TransferAtokensV2(
				data._supplyTokens.length,
				aaveV2,
				data.aTokens,
				data.supplyAmts,
				data._supplyTokens,
				userAccount
			);
		}
		// withdraw v2 supplied tokens
		_WithdrawTokensFromV2(
			data._supplyTokens.length,
			aaveV2,
			data.supplyAmts,
			data._supplyTokens
		);
		// deposit tokens in v3
		_depositTokensV3(
			data._supplyTokensV3.length,
			aaveV3,
			data.supplyAmts,
			data._supplyTokensV3
		);

		// borrow assets in aave v3 after migrating position
		if (data.convertStable) {
			_BorrowVariableV3(
				data._borrowTokensV3.length,
				aaveV3,
				data._borrowTokensV3,
				data.totalBorrowAmtsWithFee
			);
		} else {
			_BorrowStableV3(
				data._borrowTokensV3.length,
				aaveV3,
				data._borrowTokensV3,
				data.stableBorrowAmtsWithFee
			);
			_BorrowVariableV3(
				data._borrowTokensV3.length,
				aaveV3,
				data._borrowTokensV3,
				data.variableBorrowAmtsWithFee
			);
		}

		_eventName = "LogAaveImportV2ToV3(address,bool,bool,address[],address[],address[],address[],uint256[],uint256[],uint256[],uint256[])";
		_eventParam = abi.encode(
			userAccount,
			doImport,
			inputData.convertStable,
			inputData.supplyTokens,
			data._supplyTokensV3,
			inputData.borrowTokens,
			data._borrowTokensV3,
			inputData.flashLoanFees,
			data.supplyAmts,
			data.stableBorrowAmts,
			data.variableBorrowAmts
		);
	}

	/**
	 * @dev Import aave position .
	 * @notice Import EOA's aave V2 position to DSA's aave v3 position
	 * @param userAccount The address of the EOA from which aave position will be imported
	 * @param inputData The struct containing all the neccessary input data
	 */
	function importAaveV2ToV3(
		address userAccount,
		ImportInputData memory inputData
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(_eventName, _eventParam) = _importAave(userAccount, inputData, true);
	}

	/**
	 * @dev Migrate aave position .
	 * @notice Migrate DSA's aave V2 position to DSA's aave v3 position
	 * @param inputData The struct containing all the neccessary input data
	 */
	function migrateAaveV2ToV3(ImportInputData memory inputData)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(_eventName, _eventParam) = _importAave(
			address(this),
			inputData,
			false
		);
	}
}

contract ConnectV2AaveV2ToV3MigrationAvalanche is _AaveV2ToV3MigrationResolver {
	string public constant name = "Aave-Import-v2-to-v3";
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

interface MemoryInterface {
    function getUint(uint id) external returns (uint num);
    function setUint(uint id, uint val) external;
}

interface AccountInterface {
    function enable(address) external;
    function disable(address) external;
    function isAuth(address) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// aave v2
interface AaveV2Interface {
	function withdraw(
		address _asset,
		uint256 _amount,
		address _to
	) external;

	function borrow(
		address _asset,
		uint256 _amount,
		uint256 _interestRateMode,
		uint16 _referralCode,
		address _onBehalfOf
	) external;

	function repay(
		address _asset,
		uint256 _amount,
		uint256 _rateMode,
		address _onBehalfOf
	) external;

	function setUserUseReserveAsCollateral(
		address _asset,
		bool _useAsCollateral
	) external;

	function getUserAccountData(address user)
		external
		view
		returns (
			uint256 totalCollateralETH,
			uint256 totalDebtETH,
			uint256 availableBorrowsETH,
			uint256 currentLiquidationThreshold,
			uint256 ltv,
			uint256 healthFactor
		);
}

interface AaveV2LendingPoolProviderInterface {
	function getLendingPool() external view returns (address);
}

// Aave Protocol Data Provider
interface AaveV2DataProviderInterface {
	function getUserReserveData(address _asset, address _user)
		external
		view
		returns (
			uint256 currentATokenBalance,
			uint256 currentStableDebt,
			uint256 currentVariableDebt,
			uint256 principalStableDebt,
			uint256 scaledVariableDebt,
			uint256 stableBorrowRate,
			uint256 liquidityRate,
			uint40 stableRateLastUpdated,
			bool usageAsCollateralEnabled
		);

	// function getReserveConfigurationData(address asset)
	// 	external
	// 	view
	// 	returns (
	// 		uint256 decimals,
	// 		uint256 ltv,
	// 		uint256 liquidationThreshold,
	// 		uint256 liquidationBonus,
	// 		uint256 reserveFactor,
	// 		bool usageAsCollateralEnabled,
	// 		bool borrowingEnabled,
	// 		bool stableBorrowRateEnabled,
	// 		bool isActive,
	// 		bool isFrozen
	// 	);

	function getReserveTokensAddresses(address asset)
		external
		view
		returns (
			address aTokenAddress,
			address stableDebtTokenAddress,
			address variableDebtTokenAddress
		);
}

interface ATokenV2Interface {
	function scaledBalanceOf(address _user) external view returns (uint256);

	function isTransferAllowed(address _user, uint256 _amount)
		external
		view
		returns (bool);

	function balanceOf(address _user) external view returns (uint256);

	function transferFrom(
		address,
		address,
		uint256
	) external returns (bool);

	function allowance(address, address) external returns (uint256);
}

// aave v3
interface AaveV3Interface {
	function supply(
		address asset,
		uint256 amount,
		address onBehalfOf,
		uint16 referralCode
	) external;

	function withdraw(
		address asset,
		uint256 amount,
		address to
	) external returns (uint256);

	function borrow(
		address asset,
		uint256 amount,
		uint256 interestRateMode,
		uint16 referralCode,
		address onBehalfOf
	) external;

	function repay(
		address asset,
		uint256 amount,
		uint256 interestRateMode,
		address onBehalfOf
	) external returns (uint256);

	function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
		external;

	function swapBorrowRateMode(address asset, uint256 interestRateMode)
		external;
}

interface AaveV3PoolProviderInterface {
	function getPool() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import { TokenInterface, AccountInterface } from "../../../common/interfaces.sol";
import "./events.sol";
import "./interfaces.sol";

abstract contract Helper is DSMath, Basic {
	/**
	 * @dev Aave referal code
	 */
	uint16 internal constant referalCode = 3228;

	/**
	 * @dev AaveV2 Lending Pool Provider
	 */
	AaveV2LendingPoolProviderInterface internal constant aaveV2Provider =
		AaveV2LendingPoolProviderInterface(
			0xb6A86025F0FE1862B372cb0ca18CE3EDe02A318f // v2 address: LendingPoolAddressProvider avax
		);

	/**
	 * @dev AaveV3 Lending Pool Provider
	 */
	AaveV3PoolProviderInterface internal constant aaveV3Provider =
		AaveV3PoolProviderInterface(
			0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb // v3 - PoolAddressesProvider Avalanche
		);

	/**
	 * @dev Aave Protocol Data Provider
	 */
	AaveV2DataProviderInterface internal constant aaveV2Data =
		AaveV2DataProviderInterface(0x65285E9dfab318f57051ab2b139ccCf232945451); // aave v2 - avax

	function getIsColl(address token, address user)
		internal
		view
		returns (bool isCol)
	{
		(, , , , , , , , isCol) = aaveV2Data.getUserReserveData(token, user);
	}

	struct ImportData {
		address[] _supplyTokens;
		address[] _supplyTokensV3;
		address[] _borrowTokens;
		address[] _borrowTokensV3;
		ATokenV2Interface[] aTokens;
		uint256[] supplyAmts;
		uint256[] variableBorrowAmts;
		uint256[] variableBorrowAmtsWithFee;
		uint256[] stableBorrowAmts;
		uint256[] stableBorrowAmtsWithFee;
		uint256[] totalBorrowAmts;
		uint256[] totalBorrowAmtsWithFee;
		bool convertStable;
	}

	struct ImportInputData {
		address[] supplyTokens;
		address[] borrowTokens;
		bool convertStable;
		uint256[] flashLoanFees;
	}
}

contract _AaveHelper is Helper {
	/*
	 ** Convert Avalanche Bridge tokens to Offical tokens. Like USDC.e to USDC
	 */
	function convertABTokens(address _token) internal pure returns (address) {
		if (_token == 0xc7198437980c041c805A1EDcbA50c1Ce5db95118) {
			// USDT.e => USDT
			return 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7;
		} else if (_token == 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664) {
			// USDC.e => USDC
			return 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
		} else {
			return _token;
		}
	}

	function getBorrowAmountV2(address _token, address userAccount)
		internal
		view
		returns (uint256 stableBorrow, uint256 variableBorrow)
	{
		(
			,
			address stableDebtTokenAddress,
			address variableDebtTokenAddress
		) = aaveV2Data.getReserveTokensAddresses(_token);

		stableBorrow = ATokenV2Interface(stableDebtTokenAddress).balanceOf(
			userAccount
		);
		variableBorrow = ATokenV2Interface(variableDebtTokenAddress).balanceOf(
			userAccount
		);
	}

	function getBorrowAmountsV2(
		address userAccount,
		AaveV2Interface aaveV2,
		ImportInputData memory inputData,
		ImportData memory data
	) internal returns (ImportData memory) {
		if (inputData.borrowTokens.length > 0) {
			data._borrowTokens = new address[](inputData.borrowTokens.length);
			data._borrowTokensV3 = new address[](inputData.borrowTokens.length);
			data.variableBorrowAmts = new uint256[](
				inputData.borrowTokens.length
			);
			data.stableBorrowAmts = new uint256[](
				inputData.borrowTokens.length
			);
			data.variableBorrowAmtsWithFee = new uint256[](
				inputData.borrowTokens.length
			);
			data.stableBorrowAmtsWithFee = new uint256[](
				inputData.borrowTokens.length
			);
			data.totalBorrowAmtsWithFee = new uint256[](
				inputData.borrowTokens.length
			);
			data.totalBorrowAmts = new uint256[](inputData.borrowTokens.length);

			for (uint256 i = 0; i < inputData.borrowTokens.length; i++) {
				for (uint256 j = i; j < inputData.borrowTokens.length; j++) {
					if (j != i) {
						require(
							inputData.borrowTokens[i] !=
								inputData.borrowTokens[j],
							"token-repeated"
						);
					}
				}
			}
			for (uint256 i = 0; i < inputData.borrowTokens.length; i++) {
				address _token = inputData.borrowTokens[i] == avaxAddr
					? wavaxAddr
					: inputData.borrowTokens[i];
				data._borrowTokens[i] = _token;
				data._borrowTokensV3[i] = convertABTokens(_token);

				(
					data.stableBorrowAmts[i],
					data.variableBorrowAmts[i]
				) = getBorrowAmountV2(_token, userAccount);

				if (data.variableBorrowAmts[i] != 0) {
					data.variableBorrowAmtsWithFee[i] = add(
						data.variableBorrowAmts[i],
						inputData.flashLoanFees[i]
					);
					data.stableBorrowAmtsWithFee[i] = data.stableBorrowAmts[i];
				} else {
					data.stableBorrowAmtsWithFee[i] = add(
						data.stableBorrowAmts[i],
						inputData.flashLoanFees[i]
					);
				}

				data.totalBorrowAmts[i] = add(
					data.stableBorrowAmts[i],
					data.variableBorrowAmts[i]
				);
				data.totalBorrowAmtsWithFee[i] = add(
					data.stableBorrowAmtsWithFee[i],
					data.variableBorrowAmtsWithFee[i]
				);

				if (data.totalBorrowAmts[i] > 0) {
					uint256 _amt = data.totalBorrowAmts[i];
					TokenInterface(_token).approve(address(aaveV2), _amt);
				}
			}
		}
		return data;
	}

	function getSupplyAmountsV2(
		address userAccount,
		ImportInputData memory inputData,
		ImportData memory data
	) internal view returns (ImportData memory) {
		data.supplyAmts = new uint256[](inputData.supplyTokens.length);
		data._supplyTokens = new address[](inputData.supplyTokens.length);
		data._supplyTokensV3 = new address[](inputData.supplyTokens.length);
		data.aTokens = new ATokenV2Interface[](inputData.supplyTokens.length);

		for (uint256 i = 0; i < inputData.supplyTokens.length; i++) {
			for (uint256 j = i; j < inputData.supplyTokens.length; j++) {
				if (j != i) {
					require(
						inputData.supplyTokens[i] != inputData.supplyTokens[j],
						"token-repeated"
					);
				}
			}
		}
		for (uint256 i = 0; i < inputData.supplyTokens.length; i++) {
			address _token = inputData.supplyTokens[i] == avaxAddr
				? wavaxAddr
				: inputData.supplyTokens[i];
			(address _aToken, , ) = aaveV2Data.getReserveTokensAddresses(
				_token
			);
			data._supplyTokens[i] = _token;
			data._supplyTokensV3[i] = convertABTokens(_token);

			data.aTokens[i] = ATokenV2Interface(_aToken);
			data.supplyAmts[i] = data.aTokens[i].balanceOf(userAccount);
		}

		return data;
	}

	function _paybackBehalfOneV2(
		AaveV2Interface aaveV2,
		address token,
		uint256 amt,
		uint256 rateMode,
		address user
	) private {
		aaveV2.repay(token, amt, rateMode, user);
	}

	function _PaybackStableV2(
		uint256 _length,
		AaveV2Interface aaveV2,
		address[] memory tokens,
		uint256[] memory amts,
		address user
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				_paybackBehalfOneV2(aaveV2, tokens[i], amts[i], 1, user);
			}
		}
	}

	function _PaybackVariableV2(
		uint256 _length,
		AaveV2Interface aaveV2,
		address[] memory tokens,
		uint256[] memory amts,
		address user
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				_paybackBehalfOneV2(aaveV2, tokens[i], amts[i], 2, user);
			}
		}
	}

	function _TransferAtokensV2(
		uint256 _length,
		AaveV2Interface aaveV2,
		ATokenV2Interface[] memory atokenContracts,
		uint256[] memory amts,
		address[] memory tokens,
		address userAccount
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				uint256 _amt = amts[i];
				require(
					atokenContracts[i].transferFrom(
						userAccount,
						address(this),
						_amt
					),
					"allowance?"
				);

				if (!getIsColl(tokens[i], address(this))) {
					aaveV2.setUserUseReserveAsCollateral(tokens[i], true);
				}
			}
		}
	}

	function _WithdrawTokensFromV2(
		uint256 _length,
		AaveV2Interface aaveV2,
		uint256[] memory amts,
		address[] memory tokens
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				uint256 _amt = amts[i];
				address _token = tokens[i];
				aaveV2.withdraw(_token, _amt, address(this));
			}
		}
	}

	function _depositTokensV3(
		uint256 _length,
		AaveV3Interface aaveV3,
		uint256[] memory amts,
		address[] memory tokens
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				uint256 _amt = amts[i];
				address _token = tokens[i];
				TokenInterface tokenContract = TokenInterface(_token);
				require(
					tokenContract.balanceOf(address(this)) >= _amt,
					"Insufficient funds to deposit in v3"
				);
				approve(tokenContract, address(aaveV3), _amt);
				aaveV3.supply(_token, _amt, address(this), referalCode);

				if (!getIsColl(_token, address(this))) {
					aaveV3.setUserUseReserveAsCollateral(_token, true);
				}
			}
		}
	}

	function _BorrowVariableV3(
		uint256 _length,
		AaveV3Interface aaveV3,
		address[] memory tokens,
		uint256[] memory amts
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				_borrowOneV3(aaveV3, tokens[i], amts[i], 2);
			}
		}
	}

	function _BorrowStableV3(
		uint256 _length,
		AaveV3Interface aaveV3,
		address[] memory tokens,
		uint256[] memory amts
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				_borrowOneV3(aaveV3, tokens[i], amts[i], 1);
			}
		}
	}

	function _borrowOneV3(
		AaveV3Interface aaveV3,
		address token,
		uint256 amt,
		uint256 rateMode
	) private {
		aaveV3.borrow(token, amt, rateMode, referalCode, address(this));
	}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
	event LogAaveImportV2ToV3(
		address indexed user,
		bool doImport,
		bool convertStable,
		address[] supplyTokensV2,
		address[] supplyTokensV3,
		address[] borrowTokensV2,
		address[] borrowTokensV3,
		uint256[] flashLoanFees,
		uint256[] supplyAmts,
		uint256[] stableBorrowAmts,
		uint256[] variableBorrowAmts
	);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

contract DSMath {
  uint constant WAD = 10 ** 18;
  uint constant RAY = 10 ** 27;

  function add(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(x, y);
  }

  function sub(uint x, uint y) internal virtual pure returns (uint z) {
    z = SafeMath.sub(x, y);
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.mul(x, y);
  }

  function div(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.div(x, y);
  }

  function wmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
  }

  function wdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
  }

  function rdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
  }

  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
  }

  function toInt(uint x) internal pure returns (int y) {
    y = int(x);
    require(y >= 0, "int-overflow");
  }

  function toRad(uint wad) internal pure returns (uint rad) {
    rad = mul(wad, 10 ** 27);
  }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { TokenInterface } from "./interfaces.sol";
import { Stores } from "./stores.sol";
import { DSMath } from "./math.sol";

abstract contract Basic is DSMath, Stores {

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function getTokenBal(TokenInterface token) internal view returns(uint _amt) {
        _amt = address(token) == avaxAddr ? address(this).balance : token.balanceOf(address(this));
    }

    function getTokensDec(TokenInterface buyAddr, TokenInterface sellAddr) internal view returns(uint buyDec, uint sellDec) {
        buyDec = address(buyAddr) == avaxAddr ?  18 : buyAddr.decimals();
        sellDec = address(sellAddr) == avaxAddr ?  18 : sellAddr.decimals();
    }

    function encodeEvent(string memory eventName, bytes memory eventParam) internal pure returns (bytes memory) {
        return abi.encode(eventName, eventParam);
    }

    function approve(TokenInterface token, address spender, uint256 amount) internal {
        try token.approve(spender, amount) {

        } catch {
            token.approve(spender, 0);
            token.approve(spender, amount);
        }
    }

    function changeAvaxAddress(address buy, address sell) internal pure returns(TokenInterface _buy, TokenInterface _sell){
        _buy = buy == avaxAddr ? TokenInterface(wavaxAddr) : TokenInterface(buy);
        _sell = sell == avaxAddr ? TokenInterface(wavaxAddr) : TokenInterface(sell);
    }

    function convertAvaxToWavax(bool isAvax, TokenInterface token, uint amount) internal {
        if(isAvax) token.deposit{value: amount}();
    }

    function convertWavaxToAvax(bool isAvax, TokenInterface token, uint amount) internal {
       if(isAvax) {
            approve(token, address(token), amount);
            token.withdraw(amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { MemoryInterface } from "./interfaces.sol";


abstract contract Stores {

  /**
   * @dev Return avax address
   */
  address constant internal avaxAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /**
   * @dev Return Wrapped AVAX address
   */
  address constant internal wavaxAddr = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

  /**
   * @dev Return memory variable address
   */
  MemoryInterface constant internal instaMemory = MemoryInterface(0x3254Ce8f5b1c82431B8f21Df01918342215825C2);

  /**
   * @dev Get Uint value from InstaMemory Contract.
   */
  function getUint(uint getId, uint val) internal returns (uint returnVal) {
    returnVal = getId == 0 ? val : instaMemory.getUint(getId);
  }

  /**
  * @dev Set Uint value in InstaMemory Contract.
  */
  function setUint(uint setId, uint val) virtual internal {
    if (setId != 0) instaMemory.setUint(setId, val);
  }

}