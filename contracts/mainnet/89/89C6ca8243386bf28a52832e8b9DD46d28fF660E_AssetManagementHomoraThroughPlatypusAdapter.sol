// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {FixedPointMath} from "../libraries/FixedPointMath.sol";
import {IDetailedERC20} from "../interfaces/IDetailedERC20.sol";
import {IVaultAdapter} from "../interfaces/IVaultAdapter.sol";
import {IBeefyVault} from "../interfaces/IBeefyVault.sol";

/// @title BeefyVaultAdapter
///
/// @dev A vault adapter implementation which wraps a beefy vault.
contract BeefyVaultAdapter is IVaultAdapter {
  using FixedPointMath for FixedPointMath.FixedDecimal;
  using SafeERC20 for IDetailedERC20;
  using SafeMath for uint256;

  /// @dev The vault that the adapter is wrapping.
  IBeefyVault public vault;

  /// @dev The address which has admin control over this contract.
  address public admin;

  /// @dev the accepted token on Beefy vault.
  IDetailedERC20 private _token;

  /// @dev The decimals of the beefy vault ERC20 (since beefy mints erc20 to store shares).
  uint256 public decimals;

  constructor(IBeefyVault _vault, address _admin) public {
    vault = _vault;
    admin = _admin;
    _token = IDetailedERC20(address(_vault.want()));
    decimals = _vault.decimals();
    updateApproval();
  }

  /// @dev A modifier which reverts if the caller is not the admin.
  modifier onlyAdmin() {
    require(admin == msg.sender, "BeefyVaultAdapter: only admin");
    _;
  }

  /// @dev Gets the token that the vault accepts.
  ///
  /// @return the accepted token.
  function token() external view override returns (IDetailedERC20) {
    return _token;
  }

  /// @dev Gets the total value of the assets that the adapter holds in the vault.
  ///
  /// @return the total assets.
  function totalValue() external view override returns (uint256) {
    return _sharesToTokens(vault.balanceOf(address(this)));
  }

  /// @dev Deposits tokens into the vault.
  ///
  /// @param _amount the amount of tokens to deposit into the vault.
  function deposit(uint256 _amount) external override {
    vault.deposit(_amount);
  }

  /// @dev Withdraws tokens from the vault to the recipient.
  ///
  /// This function reverts if the caller is not the admin.
  ///
  /// @param _recipient the account to withdraw the tokes to.
  /// @param _amount    the amount of tokens to withdraw.
  function withdraw(address _recipient, uint256 _amount) external override onlyAdmin {
    uint256 balanceBefore = _token.balanceOf(address(this));
    vault.withdraw(_tokensToShares(_amount));
    uint256 balanceAfter = _token.balanceOf(address(this));
    _token.safeTransfer(_recipient, balanceAfter - balanceBefore);
  }

  /// @dev Updates the vaults approval of the token to be the maximum value.
  function updateApproval() public {
    _token.safeApprove(address(vault), uint256(-1));
  }

  /// @dev Computes the number of tokens an amount of shares is worth.
  ///
  /// @param _sharesAmount the amount of shares.
  ///
  /// @return the number of tokens the shares are worth.
  
  function _sharesToTokens(uint256 _sharesAmount) internal view returns (uint256) {
    return _sharesAmount.mul(vault.getPricePerFullShare()).div(10**decimals);
  }

  /// @dev Computes the number of shares an amount of tokens is worth.
  ///
  /// @param _tokensAmount the amount of shares.
  ///
  /// @return the number of shares the tokens are worth.
  function _tokensToShares(uint256 _tokensAmount) internal view returns (uint256) {
    return _tokensAmount.mul(10**decimals).div(vault.getPricePerFullShare());
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

library FixedPointMath {
  uint256 public constant DECIMALS = 6;
  uint256 public constant SCALAR = 10**DECIMALS;

  struct FixedDecimal {
    uint256 x;
  }

  function fromU256(uint256 value) internal pure returns (FixedDecimal memory) {
    uint256 x;
    require(value == 0 || (x = value * SCALAR) / SCALAR == value);
    return FixedDecimal(x);
  }

  function maximumValue() internal pure returns (FixedDecimal memory) {
    return FixedDecimal(uint256(-1));
  }

  function add(FixedDecimal memory self, FixedDecimal memory value) internal pure returns (FixedDecimal memory) {
    uint256 x;
    require((x = self.x + value.x) >= self.x);
    return FixedDecimal(x);
  }

  function add(FixedDecimal memory self, uint256 value) internal pure returns (FixedDecimal memory) {
    return add(self, fromU256(value));
  }

  function sub(FixedDecimal memory self, FixedDecimal memory value) internal pure returns (FixedDecimal memory) {
    uint256 x;
    require((x = self.x - value.x) <= self.x);
    return FixedDecimal(x);
  }

  function sub(FixedDecimal memory self, uint256 value) internal pure returns (FixedDecimal memory) {
    return sub(self, fromU256(value));
  }

  function mul(FixedDecimal memory self, uint256 value) internal pure returns (FixedDecimal memory) {
    uint256 x;
    require(value == 0 || (x = self.x * value) / value == self.x);
    return FixedDecimal(x);
  }

  function div(FixedDecimal memory self, uint256 value) internal pure returns (FixedDecimal memory) {
    require(value != 0);
    return FixedDecimal(self.x / value);
  }

  function cmp(FixedDecimal memory self, FixedDecimal memory value) internal pure returns (int256) {
    if (self.x < value.x) {
      return -1;
    }

    if (self.x > value.x) {
      return 1;
    }

    return 0;
  }

  function decode(FixedDecimal memory self) internal pure returns (uint256) {
    return self.x / SCALAR;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDetailedERC20 is IERC20 {
  function name() external returns (string memory);
  function symbol() external returns (string memory);
  function decimals() external returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IDetailedERC20.sol";

/// Interface for all Vault Adapter implementations.
interface IVaultAdapter {

  /// @dev Gets the token that the adapter accepts.
  function token() external view returns (IDetailedERC20);

  /// @dev The total value of the assets deposited into the vault.
  function totalValue() external view returns (uint256);

  /// @dev Deposits funds into the vault.
  ///
  /// @param _amount  the amount of funds to deposit.
  function deposit(uint256 _amount) external;

  /// @dev Attempts to withdraw funds from the wrapped vault.
  ///
  /// The amount withdrawn to the recipient may be less than the amount requested.
  ///
  /// @param _recipient the recipient of the funds.
  /// @param _amount    the amount of funds to withdraw.
  function withdraw(address _recipient, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBeefyVault  {
    function balanceOf(address user)  external view returns (uint);
    function getPricePerFullShare() external view returns (uint256);
    function deposit(uint256) external;
    function withdraw(uint256) external;
    function want() external view returns (IERC20);
    function decimals() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {FixedPointMath} from "../libraries/FixedPointMath.sol";
import {IDetailedERC20} from "../interfaces/IDetailedERC20.sol";
import {IVaultAdapter} from "../interfaces/IVaultAdapter.sol";
import {IBeefyVault} from "../interfaces/IBeefyVault.sol";

/// @title BeefyVaultAdapter
///
/// @dev A vault adapter implementation which wraps a beefy vault.
contract BeefyVaultAdapterMock is IVaultAdapter {
  using FixedPointMath for FixedPointMath.FixedDecimal;
  using SafeERC20 for IDetailedERC20;
  using SafeMath for uint256;

  /// @dev The vault that the adapter is wrapping.
  IBeefyVault public vault;

  /// @dev The address which has admin control over this contract.
  address public admin;

  /// @dev the accepted token on Beefy vault.
  IDetailedERC20 private _token;

  /// @dev The decimals of the beefy vault ERC20 (since beefy mints erc20 to store shares).
  uint256 public decimals;

  constructor(IBeefyVault _vault) public {
    vault = _vault;
    _token = IDetailedERC20(address(_vault.want()));
    decimals = _vault.decimals();
    updateApproval();
  }

  /// @dev A modifier which reverts if the caller is not the admin.
  modifier onlyAdmin() {
    require(admin == msg.sender, "BeefyVaultAdapter: only admin");
    _;
  }

  /// @dev Gets the token that the vault accepts.
  ///
  /// @return the accepted token.
  function token() external view override returns (IDetailedERC20) {
    return _token;
  }

  /// @dev Gets the total value of the assets that the adapter holds in the vault.
  ///
  /// @return the total assets.
  function totalValue() external view override returns (uint256) {
    return _sharesToTokens(vault.balanceOf(address(this)));
  }

  /// @dev Deposits tokens into the vault.
  ///
  /// @param _amount the amount of tokens to deposit into the vault.
  function deposit(uint256 _amount) external override {
    vault.deposit(_amount);
  }

  /// @dev Withdraws tokens from the vault to the recipient.
  ///
  /// This function reverts if the caller is not the admin.
  ///
  /// @param _recipient the account to withdraw the tokes to.
  /// @param _amount    the amount of tokens to withdraw.
  function withdraw(address _recipient, uint256 _amount) external override {
    uint256 balanceBefore = _token.balanceOf(address(this));
    vault.withdraw(_tokensToShares(_amount));
    uint256 balanceAfter = _token.balanceOf(address(this));
    _token.safeTransfer(_recipient, balanceAfter - balanceBefore);
  }

  /// @dev Updates the vaults approval of the token to be the maximum value.
  function updateApproval() public {
    _token.safeApprove(address(vault), uint256(-1));
  }

  /// @dev Computes the number of tokens an amount of shares is worth.
  ///
  /// @param _sharesAmount the amount of shares.
  ///
  /// @return the number of tokens the shares are worth.
  
  function _sharesToTokens(uint256 _sharesAmount) internal view returns (uint256) {
    return _sharesAmount.mul(vault.getPricePerFullShare()).div(10**decimals);
  }

  /// @dev Computes the number of shares an amount of tokens is worth.
  ///
  /// @param _tokensAmount the amount of shares.
  ///
  /// @return the number of shares the tokens are worth.
  function _tokensToShares(uint256 _tokensAmount) internal view returns (uint256) {
    return _tokensAmount.mul(10**decimals).div(vault.getPricePerFullShare());
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interfaces/IVaultAdapter.sol";

contract VaultAdapterMock is IVaultAdapter {
  using SafeERC20 for IDetailedERC20;

  IDetailedERC20 private _token;

  constructor(IDetailedERC20 token_) public {
    _token = token_;
  }

  function token() external view override returns (IDetailedERC20) {
    return _token;
  }

  function totalValue() external view override returns (uint256) {
    return _token.balanceOf(address(this));
  }

  function deposit(uint256 _amount) external override { }

  function withdraw(address _recipient, uint256 _amount) external override {
    _token.safeTransfer(_recipient, _amount);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity = 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interfaces/ILending.sol";
import "./libraries/MerkleProof.sol";

contract Vesting is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public constant BASE_INDEX = 1e18;

    bytes32 public immutable root;
    address public immutable aux;
    address public immutable usdc;
    address public immutable lending;

    uint256 public dividendIndex;
    uint256 public totalContributions;
    uint256 public expectedContributions; 

    struct Contribution {
        uint256 amount;     // If amount > 0, user has USDC deposits on the Vesting contract. He can withdraw.
        uint256 userIndex;  // If userIndex < dividendIndex -as long as amount > 0-, user can claim AUX.
    }

    mapping(address => Contribution) public contributions;

    bool public initialized;

    event ContributionClaimed(address investor, uint256 amount);
    event ContributionsInvested(uint256 amount);
    event IndexUpdated(uint256 newIndex);
    event AuxClaimed(uint256 dividendAmount);
    event Initialized();
    event FundsWithdrawn(address user, uint256 amount);

    constructor(bytes32 _root, IERC20 _usdc, IERC20 _aux, ILending _lending, uint256 _expContributions) public {
        require(address(_usdc) != address(0), "Error: Null address");
        require(address(_lending) != address(0), "Error: Null address");
        require(_expContributions > 0, "Error: Null amount");

        root = _root;
        usdc = address(_usdc);
        aux = address(_aux);
        lending = address(_lending);

        dividendIndex = BASE_INDEX;
        expectedContributions = _expContributions;

        initialized = false;
    }

    modifier onlyInitialized() {
        require(initialized, "Error: Not initialized");
        _;
    }

    function deposit(uint256 amount) external onlyOwner nonReentrant {
        address caller = _msgSender();

        require(!initialized, "Error: Initialized");
        require(totalContributions.add(amount) <= expectedContributions, "Error: Exceeding contribution");
        
        totalContributions = totalContributions.add(amount);

        if (totalContributions == expectedContributions) {
            initialized = true;
            emit Initialized();
        }

        IERC20(usdc).safeTransferFrom(caller, address(this), amount);
        IERC20(usdc).approve(lending, amount);

        ILending(lending).deposit(amount);

        emit ContributionsInvested(amount);
    }

    function claimFundsOwnership(uint256 amount, bytes32[] calldata proof) external {
        address caller = _msgSender();

        Contribution storage con = contributions[caller];
        require(con.userIndex == 0, "Error: Contribution already claimed");

        bytes32 node = keccak256(abi.encodePacked(caller, amount));
        bool isValidProof = MerkleProof.verifyCalldata(proof, root, node);

        require(isValidProof, "Error: Invalid proof");
        
        con.amount = amount;
        con.userIndex = BASE_INDEX;

        emit ContributionClaimed(caller, amount);
    }

    function claimAUX() public onlyInitialized nonReentrant returns (uint256) {
        // Should compare current index against user index. 
        address caller = _msgSender();

        Contribution storage con = contributions[caller];
        
        require(con.userIndex != 0, "Error: User not registered");
        require(con.amount > 0, "Error: User contribution is null");

        return _claimAUX(caller, con);
    }

    function _claimAUX(address caller, Contribution storage con) internal returns (uint256) {
        if(block.timestamp >= ILending(lending).lastHarvest().add(ILending(lending).HARVEST_INTERVAL())) {
            _harvestAUX();
        }
        
        uint256 indexDiff = dividendIndex.sub(con.userIndex);
        uint256 auxDividends;

        if(indexDiff > 0) {
            auxDividends = con.amount.mul(indexDiff).div(1e6);
            IERC20(aux).safeTransfer(caller, auxDividends);

            con.userIndex = dividendIndex;

            emit AuxClaimed(auxDividends);
        }

        return auxDividends;
    }

    function withdrawFunds() external onlyInitialized nonReentrant {
        // Should reduce total contributions. Claim aux internally prior to withdrawal.
        address caller = _msgSender();

        Contribution storage con = contributions[caller];
        uint256 userFunds = con.amount;

        require(con.userIndex != 0, "Error: User not registered");
        require(userFunds > 0, "Error: User contribution is null");

        _claimAUX(caller, con);
        //console.log(dividendIndex);

        (uint256 withdrawAmount,) = ILending(lending).withdraw(userFunds);
        require(withdrawAmount == userFunds, "Error: Balance not matching");

        totalContributions = totalContributions.sub(userFunds);
        IERC20(usdc).safeTransfer(caller, userFunds);

        con.amount = 0;

        emit FundsWithdrawn(caller, userFunds);
    }

    function harvestAUX() public onlyInitialized nonReentrant returns (uint256) {
        return _harvestAUX();
    }

    function _harvestAUX() internal returns (uint256) {
        require(totalContributions > 0, "Error: Contributions fully withdrawn");

        uint256 currentVaultId = (ILending(lending).vaultCount()).sub(1);
        ILending(lending).harvest(currentVaultId);
        
        uint256 auxYield = ILending(lending).claim();
        uint256 indexAdd = auxYield.mul(1e6).div(totalContributions);
        dividendIndex = dividendIndex.add(indexAdd);

        emit IndexUpdated(dividendIndex);

        return auxYield;
    }

    function getAccruedAUX(address account) public view returns (uint256) {
        Contribution memory con = contributions[account];

        uint256 auxYield; 

        if (con.amount > 0 && con.userIndex < dividendIndex) {
            uint256 indexDiff = dividendIndex.sub(con.userIndex);
            auxYield = con.amount.mul(indexDiff).div(1e6);
        }

        return auxYield;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

interface ILending {
    function deposit(uint256 _amount) external;
    function harvest(uint256 _vaultId) external returns (uint256, uint256, uint256);
    function claim() external returns (uint256);
    function withdraw(uint256 _amount) external returns (uint256, uint256);

    function lastHarvest() external returns (uint256);
    function HARVEST_INTERVAL() external returns (uint256);
    function vaultCount() external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)
pragma solidity = 0.6.12;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity = 0.6.12;
pragma experimental ABIEncoderV2;

import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {VaultV2} from "./libraries/gsdlending/VaultV2.sol";
import {FixedPointMath} from "./libraries/FixedPointMath.sol";

import {CDPv2} from "./libraries/gsdlending/CDPv2.sol";
import {IMintableERC20} from "./interfaces/IMintableERC20.sol";
import {IVaultAdapterV2} from "./interfaces/IVaultAdapterV2.sol";
import {PriceRouter} from "./libraries/gsdlending/PriceRouter.sol";
import {IGsdStaking} from "./interfaces/IGsdStaking.sol";

contract LendingV3 is ReentrancyGuard {

    using CDPv2 for CDPv2.Data;
    using VaultV2 for VaultV2.Data;
    using VaultV2 for VaultV2.List;
    using SafeERC20 for IMintableERC20;
    using SafeMath for uint256;
    using Address for address;
    using PriceRouter for PriceRouter.Router;
    using FixedPointMath for FixedPointMath.FixedDecimal;

    address public constant ZERO_ADDRESS = address(0);

    /// @dev Resolution for all fixed point numeric parameters which represent percents. The resolution allows for a
    /// granularity of 0.01% increments.
    uint256 public constant PERCENT_RESOLUTION = 10000;

    PriceRouter.Router public _router;

    /// @dev usdc token.
    IMintableERC20 public usdcToken;

    /// @dev aux token.
    IMintableERC20 public auxToken;

    /// @dev The address of the account which currently has administrative capabilities over this contract.
    address public governance;

    /// @dev The address of the pending governance.
    address public pendingGovernance;

    /// @dev The address of the account which can initiate an emergency withdraw of funds in a vault.
    address public sentinel;

    /// @dev The address of the staking contract to receive aux for GSD staking rewards.
    address public staking;

    /// @dev The percent of each profitable harvest that will go to the staking contract.
    uint256 public stakingFee;

    /// @dev The address of the contract which will receive fees.
    address public rewards;

    /// @dev The percent of each profitable harvest that will go to the rewards contract.
    uint256 public harvestFee;

    /// @dev The total amount the native token deposited into the system that is owned by external users.
    uint256 public totalDepositedUsdc;

    /// @dev A flag indicating if the contract has been initialized yet.
    bool public initialized;

    /// @dev A flag indicating if deposits and flushes should be halted and if all parties should be able to recall
    /// from the active vault.
    bool public emergencyExit;

    /// @dev when movemetns are bigger than this number flush is activated.
    uint256 public flushActivator;

    /// @dev A list of all of the vaults. The last element of the list is the vault that is currently being used for
    /// deposits and withdraws. Vaults before the last element are considered inactive and are expected to be cleared.
    VaultV2.List private _vaults;

    /// @dev The context shared between the CDPs.
    CDPv2.Context private _ctx;

    /// @dev A mapping of all of the user CDPs. If a user wishes to have multiple CDPs they will have to either
    /// create a new address or set up a proxy contract that interfaces with this contract.
    mapping(address => CDPv2.Data) private _cdps;

    struct HarvestInfo {
        uint256 lastHarvestPeriod; // Measured in seconds
        uint256 lastHarvestAmount; // Measured in USDC.
    }

    uint256 public lastHarvest; // timestamp
    HarvestInfo public harvestInfo;

    uint256 public HARVEST_INTERVAL; 

    // Events.

    event GovernanceUpdated(address governance);

    event PendingGovernanceUpdated(address pendingGovernance);

    event SentinelUpdated(address sentinel);

    event ActiveVaultUpdated(IVaultAdapterV2 indexed adapter);

    event RewardsUpdated(address treasury);

    event HarvestFeeUpdated(uint256 fee);

    event StakingUpdated(address stakingContract);

    event StakingFeeUpdated(uint256 stakingFee);

    event FlushActivatorUpdated(uint256 flushActivator);

    event AuxPriceRouterUpdated(address router);

    event TokensDeposited(address indexed account, uint256 amount);

    event EmergencyExitUpdated(bool status);

    event FundsFlushed(uint256 amount);

    event FundsHarvested(uint256 withdrawnAmount, uint256 decreasedValue, uint256 realizedAux);

    event TokensWithdrawn(address indexed account, uint256 requestedAmount, uint256 withdrawnAmount, uint256 decreasedValue);

    event FundsRecalled(uint256 indexed vaultId, uint256 withdrawnAmount, uint256 decreasedValue);

    event AuxClaimed(address indexed account, uint256 auxAmount);

    event HarvestIntervalUpdated(uint256 interval);

    event AutoCompound(address indexed account, uint256 auxYield, uint256 usdcAmount);

    constructor(IMintableERC20 _usdctoken, IMintableERC20 _auxtoken, address _governance, address _sentinel) public {
        require(_governance != ZERO_ADDRESS, "Error: Cannot be the null address");
        require(_sentinel != ZERO_ADDRESS, "Error: Cannot be the null address");

        usdcToken = _usdctoken;
        auxToken = _auxtoken;

        sentinel = _sentinel;
        governance = _governance;
        flushActivator = 10000 * 1e6; // Ten thousand

        HARVEST_INTERVAL = 43200; // In seconds, equals 12 hours. Should be modifiable by gov.

        _ctx.accumulatedYieldWeight = FixedPointMath.FixedDecimal(0);
    }

    /// @dev Checks that the current message sender or caller is the governance address.
    ///
    ///
    modifier onlyGov() {
        require(msg.sender == governance, "GsdLending: only governance");
        _;
    }

    /// @dev Checks that the contract is in an initialized state.
    ///
    /// This is used over a modifier to reduce the size of the contract
    modifier expectInitialized() {
        require(initialized, "GsdLending: not initialized");
        _;
    }

    /// @dev Sets the pending governance.
    ///
    /// This function reverts if the new pending governance is the zero address or the caller is not the current
    /// governance. This is to prevent the contract governance being set to the zero address which would deadlock
    /// privileged contract functionality.
    ///
    /// @param _pendingGovernance the new pending governance.
    function setPendingGovernance(address _pendingGovernance) external onlyGov {
        require(_pendingGovernance != ZERO_ADDRESS, "Error: Cannot be the null address");

        pendingGovernance = _pendingGovernance;

        emit PendingGovernanceUpdated(_pendingGovernance);
    }

    /// @dev Accepts the role as governance.
    ///
    /// This function reverts if the caller is not the new pending governance.
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "Error: Sender is not pendingGovernance");

        //address _pendingGovernance = pendingGovernance;
        governance = pendingGovernance;
        pendingGovernance = address(0);

        emit GovernanceUpdated(governance);
    }

    function setSentinel(address _sentinel) external onlyGov {
        require(_sentinel != ZERO_ADDRESS, "Error: Cannot be the null address");

        sentinel = _sentinel;

        emit SentinelUpdated(_sentinel);
    }

    /// @dev Initializes the contract.
    ///
    /// This function checks that the transmuter and rewards have been set and sets up the active vault.
    ///
    /// @param _adapter the vault adapter of the active vault.
    function initialize(IVaultAdapterV2 _adapter) external onlyGov {
        require(!initialized, "GsdLending: already initialized");
        
        require(staking != ZERO_ADDRESS, "Error: Cannot be the null address");
        require(rewards != ZERO_ADDRESS, "Error: Cannot be the null address");

        _updateActiveVault(_adapter);
        initialized = true;
    }

    /// @dev Migrates the system to a new vault.
    ///
    /// This function reverts if the vault adapter is the zero address, if the token that the vault adapter accepts
    /// is not the token that this contract defines as the parent asset, or if the contract has not yet been initialized.
    ///
    /// @param _adapter the adapter for the vault the system will migrate to.
    function migrate(IVaultAdapterV2 _adapter) external expectInitialized onlyGov {
        _updateActiveVault(_adapter);
    }

    /// @dev Updates the active vault.
    ///
    /// This function reverts if the vault adapter is the zero address, if the token that the vault adapter accepts
    /// is not the token that this contract defines as the parent asset, or if the contract has not yet been initialized.
    ///
    /// @param _adapter the adapter for the new active vault.
    function _updateActiveVault(IVaultAdapterV2 _adapter) internal {
        require(_adapter != IVaultAdapterV2(ZERO_ADDRESS), "Error: Cannot be the null address");
        require(_adapter.token() == usdcToken, "GsdLending: token mismatch");

        bool check = IMintableERC20(usdcToken).approve(address(_adapter), type(uint256).max);
        require(check, "Error: Check reverted");

        _vaults.push(VaultV2.Data({adapter: _adapter, totalDeposited: 0}));

        emit ActiveVaultUpdated(_adapter);
    }

    // Sets the AUXUSDC price getter from TraderJoe DEX.
    function setAuxPriceRouterAddress(address router) external onlyGov {
        require(router != address(0), "Error: Cannot be the null address");

        _router = PriceRouter.Router({_router: router, _aux: address(auxToken), _usdc: address(usdcToken)});

        emit AuxPriceRouterUpdated(router);
    }

    /// @dev Sets if the contract should enter emergency exit mode.
    ///
    /// @param _emergencyExit if the contract should enter emergency exit mode.
    function setEmergencyExit(bool _emergencyExit) external {
        require(msg.sender == governance || msg.sender == sentinel, "Error: Caller not allowed");

        emergencyExit = _emergencyExit;

        emit EmergencyExitUpdated(_emergencyExit);
    }

    /// @dev Sets the flushActivator.
    ///
    /// @param _flushActivator the new flushActivator.
    function setFlushActivator(uint256 _flushActivator) external onlyGov {
        flushActivator = _flushActivator;

        emit FlushActivatorUpdated(_flushActivator);
    }

    /// @dev Sets the staking contract.
    ///
    /// This function reverts if the new staking contract is the zero address or the caller is not the current governance.
    ///
    /// @param _staking the new rewards contract.
    function setStaking(address _staking) external onlyGov {
        // Check that the staking address is not the zero address. Setting the staking to the zero address would break
        // transfers to the address because of `safeTransfer` checks.
        require(_staking != ZERO_ADDRESS, "Error: Cannot be the null address");

        staking = _staking;

        emit StakingUpdated(_staking);
    }

    /// @dev Sets the staking fee.
    ///
    /// This function reverts if the caller is not the current governance.
    ///
    /// @param _stakingFee the new staking fee.
    function setStakingFee(uint256 _stakingFee) external onlyGov {
        // Check that the staking fee is within the acceptable range. Setting the staking fee greater than 100% could
        // potentially break internal logic when calculating the staking fee.
        require(_stakingFee.add(harvestFee) <= PERCENT_RESOLUTION, "GsdLending: Fee above maximum");

        stakingFee = _stakingFee;

        emit StakingFeeUpdated(_stakingFee);
    }

    /// @dev Sets the rewards contract.
    ///
    /// This function reverts if the new rewards contract is the zero address or the caller is not the current governance.
    ///
    /// @param _rewards the new rewards contract.
    function setRewards(address _rewards) external onlyGov {
        // Check that the rewards address is not the zero address. Setting the rewards to the zero address would break
        // transfers to the address because of `safeTransfer` checks.
        require(_rewards != ZERO_ADDRESS, "Error: Cannot be the null address");

        rewards = _rewards;

        emit RewardsUpdated(_rewards);
    }

    /// @dev Sets the harvest fee.
    ///
    /// This function reverts if the caller is not the current governance.
    ///
    /// @param _harvestFee the new harvest fee.
    function setHarvestFee(uint256 _harvestFee) external onlyGov {
        // Check that the harvest fee is within the acceptable range. Setting the harvest fee greater than 100% could
        // potentially break internal logic when calculating the harvest fee.
        require(_harvestFee.add(stakingFee) <= PERCENT_RESOLUTION, "GsdLending: Fee above maximum");

        harvestFee = _harvestFee;
        emit HarvestFeeUpdated(_harvestFee);
    }

    function setHarvestInterval(uint256 _interval) external onlyGov {
        HARVEST_INTERVAL = _interval;
        
        emit HarvestIntervalUpdated(_interval);
    }

    /// @dev Flushes buffered tokens to the active vault.
    ///
    /// This function reverts if an emergency exit is active. This is in place to prevent the potential loss of
    /// additional funds.
    ///
    /// @return the amount of tokens flushed to the active vault.
    function flush() external nonReentrant expectInitialized returns (uint256) {
        // Prevent flushing to the active vault when an emergency exit is enabled to prevent potential loss of funds if
        // the active vault is poisoned for any reason.
        require(!emergencyExit, "Error: Emergency pause enabled");

        return _flushActiveVault();
    }

    /// @dev Internal function to flush buffered tokens to the active vault.
    ///
    /// This function reverts if an emergency exit is active. This is in place to prevent the potential loss of
    /// additional funds.
    ///
    /// @return the amount of tokens flushed to the active vault.
    function _flushActiveVault() internal returns (uint256) {
        VaultV2.Data storage _activeVault = _vaults.last();
        uint256 _depositedAmount = _activeVault.depositAll();

        emit FundsFlushed(_depositedAmount);

        return _depositedAmount;
    }

    function harvest(uint256 _vaultId) public expectInitialized returns (uint256, uint256, uint256) {
        VaultV2.Data storage _vault = _vaults.get(_vaultId);
        HarvestInfo storage _harvest = harvestInfo;

        uint256 _realisedAux;

        //console.log("Harvesting in Lending contract...");
        (uint256 _harvestedAmount, uint256 _decreasedValue) = _vault.harvest(address(this));
        //console.log("Harvest done in Lending contract");

        if(_harvestedAmount > 0) {
            //console.log("Harvested USDC:", _harvestedAmount);

            _realisedAux = _router.swapUsdcForAux(_harvestedAmount);
            require(_realisedAux > 0, "Error: Swap issues");
            //console.log("Swapped AUX:", _realisedAux);

            uint256 _stakingAmount = _realisedAux.mul(stakingFee).div(PERCENT_RESOLUTION);
            uint256 _feeAmount = _realisedAux.mul(harvestFee).div(PERCENT_RESOLUTION);
            uint256 _distributeAmount = _realisedAux.sub(_feeAmount).sub(_stakingAmount);
            //console.log("Distribute amount:", _distributeAmount);
            //console.log("Deposited USDC:", totalDepositedUsdc);

            FixedPointMath.FixedDecimal memory _weight = FixedPointMath.fromU256(_distributeAmount).div(totalDepositedUsdc);
            //console.log("Weight:", _weight.x);

            _ctx.accumulatedYieldWeight = _ctx.accumulatedYieldWeight.add(_weight);

            if (_feeAmount > 0) {
                auxToken.safeTransfer(rewards, _feeAmount);
            }

            if (_stakingAmount > 0) {
                _distributeToStaking(_stakingAmount);
            }       

            _harvest.lastHarvestPeriod = block.timestamp.sub(lastHarvest);
            _harvest.lastHarvestAmount = _harvestedAmount;
            
            lastHarvest = block.timestamp;
        }

        emit FundsHarvested(_harvestedAmount, _decreasedValue, _realisedAux);

        return (_harvestedAmount, _decreasedValue, _realisedAux);
    }

    // User methods.

    /// @dev Deposits collateral into a CDP.
    ///
    /// This function reverts if an emergency exit is active. This is in place to prevent the potential loss of
    /// additional funds.
    ///
    /// @param _amount the amount of collateral to deposit.
    function deposit(uint256 _amount) external nonReentrant expectInitialized {
        require(!emergencyExit, "Error: Emergency pause enabled");

        CDPv2.Data storage _cdp = _cdps[msg.sender];

        if(totalDepositedUsdc > 0 && block.timestamp >= lastHarvest + HARVEST_INTERVAL) {
            harvest(_vaults.lastIndex());
        }

        _cdp.update(_ctx); 

        usdcToken.safeTransferFrom(msg.sender, address(this), _amount);

        if (_amount >= flushActivator) {
            _flushActiveVault();
        }

        if(totalDepositedUsdc == 0) {
            lastHarvest = block.timestamp;
        }

        totalDepositedUsdc = totalDepositedUsdc.add(_amount);

        _cdp.totalDeposited = _cdp.totalDeposited.add(_amount);
        _cdp.lastDeposit = block.timestamp; 

        emit TokensDeposited(msg.sender, _amount);
    }

    /// @dev Claim sender's yield from active vault.
    ///
    /// @return the amount of funds that were harvested from active vault.
    function claim() external nonReentrant expectInitialized returns (uint256) {
        CDPv2.Data storage _cdp = _cdps[msg.sender];

        if(block.timestamp >= lastHarvest + HARVEST_INTERVAL) {
            harvest(_vaults.lastIndex());

            //console.log("Lending contract balance after harvesting:", IMintableERC20(auxToken).balanceOf(address(this)));
        }

        _cdp.update(_ctx);
        //console.log("New user total credit:", _cdp.totalCredit);

        // Keep on going.
        //(uint256 _withdrawnAmount,) = _withdrawFundsTo(msg.sender, _cdp.totalCredit);
        uint256 _auxYield = _cdp.totalCredit;
        _cdp.totalCredit = 0;

        IMintableERC20(auxToken).safeTransfer(msg.sender, _auxYield);
        emit AuxClaimed(msg.sender, _auxYield);

        return _auxYield;
    }

    function autoCompound() external nonReentrant expectInitialized returns (uint256) {
        require(!emergencyExit, "Error: Emergency pause enabled");

        CDPv2.Data storage _cdp = _cdps[msg.sender];

        if(totalDepositedUsdc > 0 && block.timestamp >= lastHarvest + HARVEST_INTERVAL) {
            harvest(_vaults.lastIndex());
        }

        _cdp.update(_ctx); 

        // First swap user AUX credit back into USDC.
        uint256 auxAmount = _cdp.totalCredit;
        require(auxAmount > 0, "Error: Null AUX to auto-compound");
        _cdp.totalCredit = 0;

        uint256 _realisedUsdc = _router.swapAuxForUsdc(auxAmount);
        require(_realisedUsdc > 0, "Error: Swap issues");

        // Then deposit user USDC on the vault.
        if (_realisedUsdc >= flushActivator) {
            _flushActiveVault();
        }

        totalDepositedUsdc = totalDepositedUsdc.add(_realisedUsdc);

        _cdp.totalDeposited = _cdp.totalDeposited.add(_realisedUsdc);
        _cdp.lastDeposit = block.timestamp; 

        // Missing event for auto compounding.
        emit AutoCompound(msg.sender, auxAmount, _realisedUsdc);
    }

    /// @dev Attempts to withdraw part of a CDP's collateral.
    ///
    /// This function reverts if a deposit into the CDP was made in the same block. This is to prevent flash loan attacks
    /// on other internal or external systems.
    ///
    /// @param _amount the amount of collateral to withdraw.
    function withdraw(uint256 _amount) external nonReentrant expectInitialized returns (uint256, uint256) {
        CDPv2.Data storage _cdp = _cdps[msg.sender];
        require(block.timestamp > _cdp.lastDeposit, "Error: Flash loans not allowed");

        if(block.timestamp >= lastHarvest + HARVEST_INTERVAL) {
            harvest(_vaults.lastIndex());
        }

        _cdp.update(_ctx);

        (uint256 _withdrawnAmount, uint256 _decreasedValue) = _withdrawFundsTo(msg.sender, _amount);

        totalDepositedUsdc = totalDepositedUsdc.sub(_decreasedValue, "Exceeds maximum withdrawable amount");
        _cdp.totalDeposited = _cdp.totalDeposited.sub(_decreasedValue, "Exceeds withdrawable amount");

        emit TokensWithdrawn(msg.sender, _amount, _withdrawnAmount, _decreasedValue);

        return (_withdrawnAmount, _decreasedValue);
    }

    /// @dev Recalls an amount of deposited funds from a vault to this contract.
    ///
    /// @param _vaultId the identifier of the recall funds from.
    ///
    /// @return the amount of funds that were recalled from the vault to this contract and the decreased vault value.
    function recall(uint256 _vaultId, uint256 _amount) external nonReentrant expectInitialized returns (uint256, uint256) {
        return _recallFunds(_vaultId, _amount);
    }

    /// @dev Recalls all the deposited funds from a vault to this contract.
    ///
    /// @param _vaultId the identifier of the recall funds from.
    ///
    /// @return the amount of funds that were recalled from the vault to this contract and the decreased vault value.
    function recallAll(uint256 _vaultId) external nonReentrant expectInitialized returns (uint256, uint256) {
        VaultV2.Data storage _vault = _vaults.get(_vaultId);
        return _recallFunds(_vaultId, _vault.totalDeposited);
    }

    /// @dev Recalls an amount of funds from a vault to this contract.
    ///
    /// @param _vaultId the identifier of the recall funds from.
    /// @param _amount  the amount of funds to recall from the vault.
    ///
    /// @return the amount of funds that were recalled from the vault to this contract and the decreased vault value.
    function _recallFunds(uint256 _vaultId, uint256 _amount) internal returns (uint256, uint256) {
        require(emergencyExit || msg.sender == governance || _vaultId != _vaults.lastIndex(), "GsdLending: user does not have permission to recall funds from active vault");

        VaultV2.Data storage _vault = _vaults.get(_vaultId);
        (uint256 _withdrawnAmount, uint256 _decreasedValue) = _vault.withdraw(address(this), _amount);

        emit FundsRecalled(_vaultId, _withdrawnAmount, _decreasedValue);

        return (_withdrawnAmount, _decreasedValue);
    }

    /// @dev Attempts to withdraw funds from the active vault to the recipient.
    ///
    /// Funds will be first withdrawn from this contracts balance and then from the active vault. This function
    /// is different from `recallFunds` in that it reduces the total amount of deposited tokens by the decreased
    /// value of the vault.
    ///
    /// @param _recipient the account to withdraw the funds to.
    /// @param _amount    the amount of funds to withdraw.
    function _withdrawFundsTo(address _recipient, uint256 _amount) internal returns (uint256, uint256) {
        // Pull the funds from the buffer.
        uint256 _bufferedAmount = Math.min(_amount, usdcToken.balanceOf(address(this)));

        if (_recipient != address(this) && _bufferedAmount > 0) {
            usdcToken.safeTransfer(_recipient, _bufferedAmount);
        }

        uint256 _totalWithdrawn = _bufferedAmount;
        uint256 _totalDecreasedValue = _bufferedAmount;

        uint256 _remainingAmount = _amount.sub(_bufferedAmount);

        // Pull the remaining funds from the active vault.
        if (_remainingAmount > 0) {
            VaultV2.Data storage _activeVault = _vaults.last();

            (uint256 _withdrawAmount, uint256 _decreasedValue) = _activeVault.withdraw(_recipient, _remainingAmount);

            _totalWithdrawn = _totalWithdrawn.add(_withdrawAmount);
            _totalDecreasedValue = _totalDecreasedValue.add(_decreasedValue);
        }

        return (_totalWithdrawn, _totalDecreasedValue);
    }

    /// @dev sends tokens to the staking contract
    function _distributeToStaking(uint256 amount) internal {
        bool check = auxToken.approve(staking, amount);
        require(check, "Error: Check reverted");

        IGsdStaking(staking).deposit(amount);
    }

    // Getters.
    function accumulatedYieldWeight() external view returns (FixedPointMath.FixedDecimal memory) {
        return _ctx.accumulatedYieldWeight;
    }

    /// @dev Gets the number of vaults in the vault list.
    ///
    /// @return the vault count.
    function vaultCount() external view returns (uint256) {
        return _vaults.length();
    }    

    /// @dev Get the adapter of a vault.
    ///
    /// @param _vaultId the identifier of the vault.
    ///
    /// @return the vault adapter.
    function getVaultAdapter(uint256 _vaultId) external view returns (IVaultAdapterV2) {
        VaultV2.Data storage _vault = _vaults.get(_vaultId);
        return _vault.adapter;
    }

    /// @dev Get the total amount of the parent asset that has been deposited into a vault.
    ///
    /// @param _vaultId the identifier of the vault.
    ///
    /// @return the total amount of deposited tokens.
    function getVaultTotalDeposited(uint256 _vaultId) external view returns (uint256) {
        VaultV2.Data storage _vault = _vaults.get(_vaultId);
        return _vault.totalDeposited;
    }

    function getUserCDPData(address account) external view returns (CDPv2.Data memory) {
        CDPv2.Data storage _cdp = _cdps[account];
        return _cdp;
    }

    function getAccruedInterest(address account) external view returns (uint256) {
        CDPv2.Data storage _cdp = _cdps[account];

        uint256 _earnedYield = _cdp.getEarnedYield(_ctx);
        return _cdp.totalCredit.add(_earnedYield);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

//import "hardhat/console.sol";

import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IDetailedERC20} from "../../interfaces/IDetailedERC20.sol";
import {IVaultAdapterV2} from "../../interfaces/IVaultAdapterV2.sol";
import "hardhat/console.sol";

/// @title Pool
///
/// @dev A library which provides the Vault data struct and associated functions.
library VaultV2 {
  using VaultV2 for Data;
  using VaultV2 for List;
  using SafeERC20 for IDetailedERC20;
  using SafeMath for uint256;

  struct Data {
    IVaultAdapterV2 adapter;
    uint256 totalDeposited;
  }

  struct List {
    Data[] elements;
  }

  /// @dev Gets the total amount of assets deposited in the vault.
  ///
  /// @return the total assets.
  function totalValue(Data storage _self) internal view returns (uint256) {
    return _self.adapter.totalValue();
  }

  /// @dev Gets the total vault yield.
  ///
  /// @return the total yield.
  function totalYield(Data storage _self) internal view returns (uint256) {
    return _self.totalValue().sub(_self.totalDeposited);
  }

  /// @dev Gets the token that the vault accepts.
  ///
  /// @return the accepted token.
  function token(Data storage _self) internal view returns (IDetailedERC20) {
    return IDetailedERC20(_self.adapter.token());
  }

  /// @dev Deposits funds from the caller into the vault.
  ///
  /// @param _amount the amount of funds to deposit.
  function deposit(Data storage _self, uint256 _amount) internal returns (uint256) {
    // Push the token that the vault accepts onto the stack to save gas.
    IDetailedERC20 _token = _self.token();

    //_token.safeTransfer(address(_self.adapter), _amount);
    _token.approve(address(_self.adapter), _amount);
    _self.adapter.deposit(_amount);
    _self.totalDeposited = _self.totalDeposited.add(_amount);

    return _amount;
  }

  /// @dev Deposits the entire token balance of the caller into the vault.
  function depositAll(Data storage _self) internal returns (uint256) {
    IDetailedERC20 _token = _self.token();
    return _self.deposit(_token.balanceOf(address(this)));
  }

  /// @dev Withdraw deposited funds from the vault.
  ///
  /// @param _recipient the account to withdraw the tokens to.
  /// @param _amount    the amount of tokens to withdraw.
  function withdraw(Data storage _self, address _recipient, uint256 _amount) internal returns (uint256, uint256) {
    (uint256 _withdrawnAmount, uint256 _decreasedValue) = _self.directWithdraw(_recipient, _amount, true);
    _self.totalDeposited = _self.totalDeposited.sub(_decreasedValue);
    return (_withdrawnAmount, _decreasedValue);
  }

  /// @dev Directly withdraw deposited funds from the vault.
  ///
  /// @param _recipient the account to withdraw the tokens to.
  /// @param _amount    the amount of tokens to withdraw.
  function directWithdraw(Data storage _self, address _recipient, uint256 _amount, bool _isCapital) internal returns (uint256, uint256) {
    IDetailedERC20 _token = _self.token();

    uint256 _startingBalance = _token.balanceOf(_recipient);
    uint256 _startingTotalValue = _self.totalValue();

    _self.adapter.withdraw(_recipient, _amount, _isCapital);

    uint256 _endingBalance = _token.balanceOf(_recipient);
    uint256 _withdrawnAmount = _endingBalance.sub(_startingBalance);

    uint256 _endingTotalValue = _self.totalValue();
    uint256 _decreasedValue = _startingTotalValue.sub(_endingTotalValue);

    return (_withdrawnAmount, _decreasedValue);
  }

  /// @dev Withdraw all the deposited funds from the vault.
  ///
  /// @param _recipient the account to withdraw the tokens to.
  function withdrawAll(Data storage _self, address _recipient) internal returns (uint256, uint256) {
    return _self.withdraw(_recipient, _self.totalDeposited);
  }

  /// @dev Harvests yield from the vault.
  ///
  /// @param _recipient the account to withdraw the harvested yield to.
  function harvest(Data storage _self, address _recipient) internal returns (uint256, uint256) {
    if (_self.totalValue() <= _self.totalDeposited) {
      return (0, 0);
    }
    uint256 _withdrawAmount = _self.totalValue().sub(_self.totalDeposited);
    return _self.directWithdraw(_recipient, _withdrawAmount, false);
  }

  /// @dev Adds a element to the list.
  ///
  /// @param _element the element to add.
  function push(List storage _self, Data memory _element) internal {
    _self.elements.push(_element);
  }

  /// @dev Gets a element from the list.
  ///
  /// @param _index the index in the list.
  ///
  /// @return the element at the specified index.
  function get(List storage _self, uint256 _index) internal view returns (Data storage) {
    return _self.elements[_index];
  }

  /// @dev Gets the last element in the list.
  ///
  /// This function will revert if there are no elements in the list.
  ///
  /// @return the last element in the list.
  function last(List storage _self) internal view returns (Data storage) {
    return _self.elements[_self.lastIndex()];
  }

  /// @dev Gets the index of the last element in the list.
  ///
  /// This function will revert if there are no elements in the list.
  ///
  /// @return the index of the last element.
  function lastIndex(List storage _self) internal view returns (uint256) {
    uint256 _length = _self.length();
    return _length.sub(1, "Vault.List: empty");
  }

  /// @dev Gets the number of elements in the list.
  ///
  /// @return the number of elements.
  function length(List storage _self) internal view returns (uint256) {
    return _self.elements.length;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {FixedPointMath} from "../FixedPointMath.sol";
import {IDetailedERC20} from "../../interfaces/IDetailedERC20.sol";
import "hardhat/console.sol";

library CDPv2 {
    using CDPv2 for Data;
    using FixedPointMath for FixedPointMath.FixedDecimal;
    using SafeERC20 for IDetailedERC20;
    using SafeMath for uint256;

    struct Context {
        FixedPointMath.FixedDecimal accumulatedYieldWeight;
    }

    struct Data {
        uint256 totalDeposited;       // In USDC, 6-decimals units.
        uint256 lastDeposit;          // In timestamp, not block number.
        uint256 totalCredit;          // In AUX, 18-decimals units.
        FixedPointMath.FixedDecimal lastAccumulatedYieldWeight;
    }

    function update(Data storage _self, Context storage _ctx) internal {
        uint256 _earnedYield = _self.getEarnedYield(_ctx);

        _self.totalCredit = _self.totalCredit.add(_earnedYield);
        _self.lastAccumulatedYieldWeight = _ctx.accumulatedYieldWeight;
    }

    function getEarnedYield(Data storage _self, Context storage _ctx) internal view returns (uint256) {
        FixedPointMath.FixedDecimal memory _currentAccumulatedYieldWeight = _ctx.accumulatedYieldWeight;
        FixedPointMath.FixedDecimal memory _lastAccumulatedYieldWeight = _self.lastAccumulatedYieldWeight;

        if (_currentAccumulatedYieldWeight.cmp(_lastAccumulatedYieldWeight) == 0) {
            return 0;
        }

        return _currentAccumulatedYieldWeight.sub(_lastAccumulatedYieldWeight).mul(_self.totalDeposited).decode();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;


import {IDetailedERC20} from "./IDetailedERC20.sol";

interface IMintableERC20 is IDetailedERC20{
  function mint(address _recipient, uint256 _amount) external;
  function burnFrom(address account, uint256 amount) external;
  function hasMinted(address sender) external returns (uint256);
  function lowerHasMinted(uint256 amount)external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IDetailedERC20.sol";

/// Interface for all Vault Adapter implementations.
interface IVaultAdapterV2 {

  /// @dev Gets the token that the adapter accepts.
  function token() external view returns (IDetailedERC20);

  /// @dev The total value of the assets deposited into the vault.
  function totalValue() external view returns (uint256);

  /// @dev Deposits funds into the vault.
  ///
  /// @param _amount  the amount of funds to deposit.
  function deposit(uint256 _amount) external;

  /// @dev Attempts to withdraw funds from the wrapped vault.
  ///
  /// The amount withdrawn to the recipient may be less than the amount requested.
  ///
  /// @param _recipient the recipient of the funds.
  /// @param _amount    the amount of funds to withdraw.
  function withdraw(address _recipient, uint256 _amount, bool _isCapital) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import "../../interfaces/IDetailedERC20.sol";
import "../../interfaces/IJoeRouter.sol";

library PriceRouter {

    using SafeMath for uint256;

    struct Router {
        address _router;
        address _aux;
        address _usdc;
    }

    uint256 public constant AUX_UNIT = 1e18;
    uint256 public constant USDC_UNIT = 1e6;

    function auxToUsdcAmount(Router storage _self, uint256 _amount) internal view returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = _self._aux;
        path[1] = _self._usdc;

        uint256[] memory amounts = IJoeRouter(_self._router).getAmountsOut(AUX_UNIT, path);
        require(amounts[1] > 0, "Error: Null price");
        
        return amounts[1].mul(_amount).div(AUX_UNIT);
    }

    function usdcToAuxAmount(Router storage _self, uint256 _amount) internal view returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = _self._usdc;
        path[1] = _self._aux;

        uint256[] memory amounts = IJoeRouter(_self._router).getAmountsOut(USDC_UNIT, path);
        require(amounts[1] > 0, "Error: Null price");
        
        return amounts[1].mul(_amount).div(USDC_UNIT);
    }

    function swapUsdcForAux(Router storage _self, uint256 _amount) internal returns (uint256) {
        uint256 auxBalance = IDetailedERC20(_self._aux).balanceOf(address(this));

        // do the swap.
        address[] memory path = new address[](2);
        path[0] = _self._usdc;
        path[1] = _self._aux;

        IDetailedERC20(_self._usdc).approve(_self._router, _amount);

        uint256[] memory amounts = IJoeRouter(_self._router).getAmountsOut(_amount, path);
        uint256 minAuxAccepted = amounts[amounts.length - 1].mul(95).div(100);

        IJoeRouter(_self._router).
            swapExactTokensForTokensSupportingFeeOnTransferTokens(_amount, minAuxAccepted, path, address(this), block.timestamp);

        uint256 auxBalanceNew = IDetailedERC20(_self._aux).balanceOf(address(this));
        uint256 realisedAux = auxBalanceNew.sub(auxBalance);

        return realisedAux;
    }

    function swapAuxForUsdc(Router storage _self, uint256 _amount) internal returns (uint256) {
        uint256 usdcBalance = IDetailedERC20(_self._usdc).balanceOf(address(this));

        // do the swap.
        address[] memory path = new address[](2);
        path[0] = _self._aux;
        path[1] = _self._usdc;

        IDetailedERC20(_self._aux).approve(_self._router, _amount);

        uint256[] memory amounts = IJoeRouter(_self._router).getAmountsOut(_amount, path);
        uint256 minUsdcAccepted = amounts[amounts.length - 1].mul(95).div(100);

        IJoeRouter(_self._router).
            swapExactTokensForTokensSupportingFeeOnTransferTokens(_amount, minUsdcAccepted, path, address(this), block.timestamp);

        uint256 usdcBalanceNew = IDetailedERC20(_self._usdc).balanceOf(address(this));
        uint256 realisedUsdc = usdcBalanceNew.sub(usdcBalance);

        return realisedUsdc;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IGsdStaking  {
  function deposit (uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IJoeRouter {
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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

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

// SPDX-License-Identifier: MIT
pragma solidity = 0.6.12;
pragma experimental ABIEncoderV2;

import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Vault} from "./libraries/gsdlending/Vault.sol";
import {FixedPointMath} from "./libraries/FixedPointMath.sol";

import {CDPv2} from "./libraries/gsdlending/CDPv2.sol";
import {IMintableERC20} from "./interfaces/IMintableERC20.sol";
import {IVaultAdapter} from "./interfaces/IVaultAdapter.sol";
import {PriceRouter} from "./libraries/gsdlending/PriceRouter.sol";
import {IGsdStaking} from "./interfaces/IGsdStaking.sol";

import "hardhat/console.sol";

contract LendingV2 is ReentrancyGuard {

    using CDPv2 for CDPv2.Data;
    using Vault for Vault.Data;
    using Vault for Vault.List;
    using SafeERC20 for IMintableERC20;
    using SafeMath for uint256;
    using Address for address;
    using PriceRouter for PriceRouter.Router;
    using FixedPointMath for FixedPointMath.FixedDecimal;

    address public constant ZERO_ADDRESS = address(0);

    /// @dev Resolution for all fixed point numeric parameters which represent percents. The resolution allows for a
    /// granularity of 0.01% increments.
    uint256 public constant PERCENT_RESOLUTION = 10000;

    PriceRouter.Router public _router;

    /// @dev usdc token.
    IMintableERC20 public usdcToken;

    /// @dev aux token.
    IMintableERC20 public auxToken;

    /// @dev The address of the account which currently has administrative capabilities over this contract.
    address public governance;

    /// @dev The address of the pending governance.
    address public pendingGovernance;

    /// @dev The address of the account which can initiate an emergency withdraw of funds in a vault.
    address public sentinel;

    /// @dev The address of the staking contract to receive aux for GSD staking rewards.
    address public staking;

    /// @dev The percent of each profitable harvest that will go to the staking contract.
    uint256 public stakingFee;

    /// @dev The address of the contract which will receive fees.
    address public rewards;

    /// @dev The percent of each profitable harvest that will go to the rewards contract.
    uint256 public harvestFee;

    /// @dev The total amount the native token deposited into the system that is owned by external users.
    uint256 public totalDepositedUsdc;

    /// @dev A flag indicating if the contract has been initialized yet.
    bool public initialized;

    /// @dev A flag indicating if deposits and flushes should be halted and if all parties should be able to recall
    /// from the active vault.
    bool public emergencyExit;

    /// @dev when movemetns are bigger than this number flush is activated.
    uint256 public flushActivator;

    /// @dev A list of all of the vaults. The last element of the list is the vault that is currently being used for
    /// deposits and withdraws. Vaults before the last element are considered inactive and are expected to be cleared.
    Vault.List private _vaults;

    /// @dev The context shared between the CDPs.
    CDPv2.Context private _ctx;

    /// @dev A mapping of all of the user CDPs. If a user wishes to have multiple CDPs they will have to either
    /// create a new address or set up a proxy contract that interfaces with this contract.
    mapping(address => CDPv2.Data) private _cdps;

    struct HarvestInfo {
        uint256 lastHarvestPeriod; // Measured in seconds
        uint256 lastHarvestAmount; // Measured in USDC.
    }

    uint256 public lastHarvest; // timestamp
    HarvestInfo public harvestInfo;

    uint256 public HARVEST_INTERVAL; 

    // Events.

    event GovernanceUpdated(address governance);

    event PendingGovernanceUpdated(address pendingGovernance);

    event SentinelUpdated(address sentinel);

    event ActiveVaultUpdated(IVaultAdapter indexed adapter);

    event RewardsUpdated(address treasury);

    event HarvestFeeUpdated(uint256 fee);

    event StakingUpdated(address stakingContract);

    event StakingFeeUpdated(uint256 stakingFee);

    event FlushActivatorUpdated(uint256 flushActivator);

    event AuxPriceRouterUpdated(address router);

    event TokensDeposited(address indexed account, uint256 amount);

    event EmergencyExitUpdated(bool status);

    event FundsFlushed(uint256 amount);

    event FundsHarvested(uint256 withdrawnAmount, uint256 decreasedValue, uint256 realizedAux);

    event TokensWithdrawn(address indexed account, uint256 requestedAmount, uint256 withdrawnAmount, uint256 decreasedValue);

    event FundsRecalled(uint256 indexed vaultId, uint256 withdrawnAmount, uint256 decreasedValue);

    event AuxClaimed(address indexed account, uint256 auxAmount);

    event HarvestIntervalUpdated(uint256 interval);



    constructor(IMintableERC20 _usdctoken, IMintableERC20 _auxtoken, address _governance, address _sentinel) public {
        require(_governance != ZERO_ADDRESS, "Error: Cannot be the null address");
        require(_sentinel != ZERO_ADDRESS, "Error: Cannot be the null address");

        usdcToken = _usdctoken;
        auxToken = _auxtoken;

        sentinel = _sentinel;
        governance = _governance;
        flushActivator = 10000 * 1e6; // Ten thousand

        HARVEST_INTERVAL = 43200; // In seconds, equals 12 hours. Should be modifiable by gov.

        _ctx.accumulatedYieldWeight = FixedPointMath.FixedDecimal(0);
    }

    /// @dev Checks that the current message sender or caller is the governance address.
    ///
    ///
    modifier onlyGov() {
        require(msg.sender == governance, "GsdLending: only governance");
        _;
    }

    /// @dev Checks that the contract is in an initialized state.
    ///
    /// This is used over a modifier to reduce the size of the contract
    modifier expectInitialized() {
        require(initialized, "GsdLending: not initialized");
        _;
    }

    /// @dev Sets the pending governance.
    ///
    /// This function reverts if the new pending governance is the zero address or the caller is not the current
    /// governance. This is to prevent the contract governance being set to the zero address which would deadlock
    /// privileged contract functionality.
    ///
    /// @param _pendingGovernance the new pending governance.
    function setPendingGovernance(address _pendingGovernance) external onlyGov {
        require(_pendingGovernance != ZERO_ADDRESS, "Error: Cannot be the null address");

        pendingGovernance = _pendingGovernance;

        emit PendingGovernanceUpdated(_pendingGovernance);
    }

    /// @dev Accepts the role as governance.
    ///
    /// This function reverts if the caller is not the new pending governance.
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "Error: Sender is not pendingGovernance");

        address _pendingGovernance = pendingGovernance;
        governance = _pendingGovernance;

        emit GovernanceUpdated(_pendingGovernance);
    }

    function setSentinel(address _sentinel) external onlyGov {
        require(_sentinel != ZERO_ADDRESS, "Error: Cannot be the null address");

        sentinel = _sentinel;

        emit SentinelUpdated(_sentinel);
    }

    /// @dev Initializes the contract.
    ///
    /// This function checks that the transmuter and rewards have been set and sets up the active vault.
    ///
    /// @param _adapter the vault adapter of the active vault.
    function initialize(IVaultAdapter _adapter) external onlyGov {
        require(!initialized, "GsdLending: already initialized");
        
        require(staking != ZERO_ADDRESS, "Error: Cannot be the null address");
        require(rewards != ZERO_ADDRESS, "Error: Cannot be the null address");

        _updateActiveVault(_adapter);
        initialized = true;
    }

    /// @dev Migrates the system to a new vault.
    ///
    /// This function reverts if the vault adapter is the zero address, if the token that the vault adapter accepts
    /// is not the token that this contract defines as the parent asset, or if the contract has not yet been initialized.
    ///
    /// @param _adapter the adapter for the vault the system will migrate to.
    function migrate(IVaultAdapter _adapter) external expectInitialized onlyGov {
        _updateActiveVault(_adapter);
    }

    /// @dev Updates the active vault.
    ///
    /// This function reverts if the vault adapter is the zero address, if the token that the vault adapter accepts
    /// is not the token that this contract defines as the parent asset, or if the contract has not yet been initialized.
    ///
    /// @param _adapter the adapter for the new active vault.
    function _updateActiveVault(IVaultAdapter _adapter) internal {
        require(_adapter != IVaultAdapter(ZERO_ADDRESS), "Error: Cannot be the null address");
        require(_adapter.token() == usdcToken, "GsdLending: token mismatch");

        _vaults.push(Vault.Data({adapter: _adapter, totalDeposited: 0}));

        emit ActiveVaultUpdated(_adapter);
    }

    // Sets the AUXUSDC price getter from TraderJoe DEX.
    function setAuxPriceRouterAddress(address router) external onlyGov {
        require(router != address(0), "Error: Cannot be the null address");

        _router = PriceRouter.Router({_router: router, _aux: address(auxToken), _usdc: address(usdcToken)});

        emit AuxPriceRouterUpdated(router);
    }

    /// @dev Sets if the contract should enter emergency exit mode.
    ///
    /// @param _emergencyExit if the contract should enter emergency exit mode.
    function setEmergencyExit(bool _emergencyExit) external {
        require(msg.sender == governance || msg.sender == sentinel, "Error: Caller not allowed");

        emergencyExit = _emergencyExit;

        emit EmergencyExitUpdated(_emergencyExit);
    }

    /// @dev Sets the flushActivator.
    ///
    /// @param _flushActivator the new flushActivator.
    function setFlushActivator(uint256 _flushActivator) external onlyGov {
        flushActivator = _flushActivator;

        emit FlushActivatorUpdated(_flushActivator);
    }

    /// @dev Sets the staking contract.
    ///
    /// This function reverts if the new staking contract is the zero address or the caller is not the current governance.
    ///
    /// @param _staking the new rewards contract.
    function setStaking(address _staking) external onlyGov {
        // Check that the staking address is not the zero address. Setting the staking to the zero address would break
        // transfers to the address because of `safeTransfer` checks.
        require(_staking != ZERO_ADDRESS, "Error: Cannot be the null address");

        staking = _staking;

        emit StakingUpdated(_staking);
    }

    /// @dev Sets the staking fee.
    ///
    /// This function reverts if the caller is not the current governance.
    ///
    /// @param _stakingFee the new staking fee.
    function setStakingFee(uint256 _stakingFee) external onlyGov {
        // Check that the staking fee is within the acceptable range. Setting the staking fee greater than 100% could
        // potentially break internal logic when calculating the staking fee.
        require(_stakingFee.add(harvestFee) <= PERCENT_RESOLUTION, "GsdLending: Fee above maximum");

        stakingFee = _stakingFee;

        emit StakingFeeUpdated(_stakingFee);
    }

    /// @dev Sets the rewards contract.
    ///
    /// This function reverts if the new rewards contract is the zero address or the caller is not the current governance.
    ///
    /// @param _rewards the new rewards contract.
    function setRewards(address _rewards) external onlyGov {
        // Check that the rewards address is not the zero address. Setting the rewards to the zero address would break
        // transfers to the address because of `safeTransfer` checks.
        require(_rewards != ZERO_ADDRESS, "Error: Cannot be the null address");

        rewards = _rewards;

        emit RewardsUpdated(_rewards);
    }

    /// @dev Sets the harvest fee.
    ///
    /// This function reverts if the caller is not the current governance.
    ///
    /// @param _harvestFee the new harvest fee.
    function setHarvestFee(uint256 _harvestFee) external onlyGov {
        // Check that the harvest fee is within the acceptable range. Setting the harvest fee greater than 100% could
        // potentially break internal logic when calculating the harvest fee.
        require(_harvestFee.add(stakingFee) <= PERCENT_RESOLUTION, "GsdLending: Fee above maximum");

        harvestFee = _harvestFee;
        emit HarvestFeeUpdated(_harvestFee);
    }

    function setHarvestInterval(uint256 _interval) external onlyGov {
        HARVEST_INTERVAL = _interval;
        
        emit HarvestIntervalUpdated(_interval);
    }

    /// @dev Flushes buffered tokens to the active vault.
    ///
    /// This function reverts if an emergency exit is active. This is in place to prevent the potential loss of
    /// additional funds.
    ///
    /// @return the amount of tokens flushed to the active vault.
    function flush() external nonReentrant expectInitialized returns (uint256) {
        // Prevent flushing to the active vault when an emergency exit is enabled to prevent potential loss of funds if
        // the active vault is poisoned for any reason.
        require(!emergencyExit, "Error: Emergency pause enabled");

        return _flushActiveVault();
    }

    /// @dev Internal function to flush buffered tokens to the active vault.
    ///
    /// This function reverts if an emergency exit is active. This is in place to prevent the potential loss of
    /// additional funds.
    ///
    /// @return the amount of tokens flushed to the active vault.
    function _flushActiveVault() internal returns (uint256) {
        Vault.Data storage _activeVault = _vaults.last();
        uint256 _depositedAmount = _activeVault.depositAll();

        emit FundsFlushed(_depositedAmount);

        return _depositedAmount;
    }

    function harvest(uint256 _vaultId) public expectInitialized returns (uint256, uint256, uint256) {
        Vault.Data storage _vault = _vaults.get(_vaultId);
        HarvestInfo storage _harvest = harvestInfo;

        uint256 _realisedAux;
        (uint256 _harvestedAmount, uint256 _decreasedValue) = _vault.harvest(address(this));

        if(_harvestedAmount > 0) {
            //console.log("Harvested USDC:", _harvestedAmount);

            _realisedAux = _router.swapUsdcForAux(_harvestedAmount);
            require(_realisedAux > 0, "Error: Swap issues");
            //console.log("Swapped AUX:", _realisedAux);

            uint256 _stakingAmount = _realisedAux.mul(stakingFee).div(PERCENT_RESOLUTION);
            uint256 _feeAmount = _realisedAux.mul(harvestFee).div(PERCENT_RESOLUTION);
            uint256 _distributeAmount = _realisedAux.sub(_feeAmount).sub(_stakingAmount);
            //console.log("Distribute amount:", _distributeAmount);
            //console.log("Deposited USDC:", totalDepositedUsdc);

            FixedPointMath.FixedDecimal memory _weight = FixedPointMath.fromU256(_distributeAmount).div(totalDepositedUsdc);
            //console.log("Weight:", _weight.x);

            _ctx.accumulatedYieldWeight = _ctx.accumulatedYieldWeight.add(_weight);

            if (_feeAmount > 0) {
                auxToken.safeTransfer(rewards, _feeAmount);
            }

            if (_stakingAmount > 0) {
                _distributeToStaking(_stakingAmount);
            }       

            _harvest.lastHarvestPeriod = block.timestamp.sub(lastHarvest);
            _harvest.lastHarvestAmount = _harvestedAmount;
            
            lastHarvest = block.timestamp;
        }

        emit FundsHarvested(_harvestedAmount, _decreasedValue, _realisedAux);

        return (_harvestedAmount, _decreasedValue, _realisedAux);
    }

    // User methods.

    /// @dev Deposits collateral into a CDP.
    ///
    /// This function reverts if an emergency exit is active. This is in place to prevent the potential loss of
    /// additional funds.
    ///
    /// @param _amount the amount of collateral to deposit.
    function deposit(uint256 _amount) external nonReentrant expectInitialized {
        require(!emergencyExit, "Error: Emergency pause enabled");

        CDPv2.Data storage _cdp = _cdps[msg.sender];

        if(totalDepositedUsdc > 0 && block.timestamp >= lastHarvest + HARVEST_INTERVAL) {
            harvest(_vaults.lastIndex());
        }

        _cdp.update(_ctx); 

        usdcToken.safeTransferFrom(msg.sender, address(this), _amount);

        if (_amount >= flushActivator) {
            _flushActiveVault();
        }

        if(totalDepositedUsdc == 0) {
            lastHarvest = block.timestamp;
        }

        totalDepositedUsdc = totalDepositedUsdc.add(_amount);

        _cdp.totalDeposited = _cdp.totalDeposited.add(_amount);
        _cdp.lastDeposit = block.timestamp; 

        emit TokensDeposited(msg.sender, _amount);
    }

    /// @dev Claim sender's yield from active vault.
    ///
    /// @return the amount of funds that were harvested from active vault.
    function claim() external nonReentrant expectInitialized returns (uint256) {
        CDPv2.Data storage _cdp = _cdps[msg.sender];

        if(block.timestamp >= lastHarvest + HARVEST_INTERVAL) {
            harvest(_vaults.lastIndex());

            //console.log("Lending contract balance after harvesting:", IMintableERC20(auxToken).balanceOf(address(this)));
        }

        _cdp.update(_ctx);
        //console.log("New user total credit:", _cdp.totalCredit);

        // Keep on going.
        //(uint256 _withdrawnAmount,) = _withdrawFundsTo(msg.sender, _cdp.totalCredit);
        uint256 _auxYield = _cdp.totalCredit;
        _cdp.totalCredit = 0;

        IMintableERC20(auxToken).safeTransfer(msg.sender, _auxYield);
        emit AuxClaimed(msg.sender, _auxYield);

        return _auxYield;
    }

    /// @dev Attempts to withdraw part of a CDP's collateral.
    ///
    /// This function reverts if a deposit into the CDP was made in the same block. This is to prevent flash loan attacks
    /// on other internal or external systems.
    ///
    /// @param _amount the amount of collateral to withdraw.
    function withdraw(uint256 _amount) external nonReentrant expectInitialized returns (uint256, uint256) {
        CDPv2.Data storage _cdp = _cdps[msg.sender];
        require(block.timestamp > _cdp.lastDeposit, "Error: Flash loans not allowed");

        if(block.timestamp > lastHarvest + HARVEST_INTERVAL) {
            harvest(_vaults.lastIndex());
        }

        _cdp.update(_ctx);

        (uint256 _withdrawnAmount, uint256 _decreasedValue) = _withdrawFundsTo(msg.sender, _amount);

        totalDepositedUsdc = totalDepositedUsdc.sub(_decreasedValue, "Exceeds maximum withdrawable amount");
        _cdp.totalDeposited = _cdp.totalDeposited.sub(_decreasedValue, "Exceeds withdrawable amount");

        emit TokensWithdrawn(msg.sender, _amount, _withdrawnAmount, _decreasedValue);

        return (_withdrawnAmount, _decreasedValue);
    }

    /// @dev Recalls an amount of deposited funds from a vault to this contract.
    ///
    /// @param _vaultId the identifier of the recall funds from.
    ///
    /// @return the amount of funds that were recalled from the vault to this contract and the decreased vault value.
    function recall(uint256 _vaultId, uint256 _amount) external nonReentrant expectInitialized returns (uint256, uint256) {
        return _recallFunds(_vaultId, _amount);
    }

    /// @dev Recalls all the deposited funds from a vault to this contract.
    ///
    /// @param _vaultId the identifier of the recall funds from.
    ///
    /// @return the amount of funds that were recalled from the vault to this contract and the decreased vault value.
    function recallAll(uint256 _vaultId) external nonReentrant expectInitialized returns (uint256, uint256) {
        Vault.Data storage _vault = _vaults.get(_vaultId);
        return _recallFunds(_vaultId, _vault.totalDeposited);
    }

    /// @dev Recalls an amount of funds from a vault to this contract.
    ///
    /// @param _vaultId the identifier of the recall funds from.
    /// @param _amount  the amount of funds to recall from the vault.
    ///
    /// @return the amount of funds that were recalled from the vault to this contract and the decreased vault value.
    function _recallFunds(uint256 _vaultId, uint256 _amount) internal returns (uint256, uint256) {
        require(emergencyExit || msg.sender == governance || _vaultId != _vaults.lastIndex(), "GsdLending: user does not have permission to recall funds from active vault");

        Vault.Data storage _vault = _vaults.get(_vaultId);
        (uint256 _withdrawnAmount, uint256 _decreasedValue) = _vault.withdraw(address(this), _amount);

        emit FundsRecalled(_vaultId, _withdrawnAmount, _decreasedValue);

        return (_withdrawnAmount, _decreasedValue);
    }

    /// @dev Attempts to withdraw funds from the active vault to the recipient.
    ///
    /// Funds will be first withdrawn from this contracts balance and then from the active vault. This function
    /// is different from `recallFunds` in that it reduces the total amount of deposited tokens by the decreased
    /// value of the vault.
    ///
    /// @param _recipient the account to withdraw the funds to.
    /// @param _amount    the amount of funds to withdraw.
    function _withdrawFundsTo(address _recipient, uint256 _amount) internal returns (uint256, uint256) {
        // Pull the funds from the buffer.
        uint256 _bufferedAmount = Math.min(_amount, usdcToken.balanceOf(address(this)));

        if (_recipient != address(this) && _bufferedAmount > 0) {
            usdcToken.safeTransfer(_recipient, _bufferedAmount);
        }

        uint256 _totalWithdrawn = _bufferedAmount;
        uint256 _totalDecreasedValue = _bufferedAmount;

        uint256 _remainingAmount = _amount.sub(_bufferedAmount);

        // Pull the remaining funds from the active vault.
        if (_remainingAmount > 0) {
            Vault.Data storage _activeVault = _vaults.last();

            (uint256 _withdrawAmount, uint256 _decreasedValue) = _activeVault.withdraw(_recipient, _remainingAmount);

            _totalWithdrawn = _totalWithdrawn.add(_withdrawAmount);
            _totalDecreasedValue = _totalDecreasedValue.add(_decreasedValue);
        }

        return (_totalWithdrawn, _totalDecreasedValue);
    }

    /// @dev sends tokens to the staking contract
    function _distributeToStaking(uint256 amount) internal {
        auxToken.approve(staking, amount);
        IGsdStaking(staking).deposit(amount);
    }

    // Getters.
    function accumulatedYieldWeight() external view returns (FixedPointMath.FixedDecimal memory) {
        return _ctx.accumulatedYieldWeight;
    }

    /// @dev Gets the number of vaults in the vault list.
    ///
    /// @return the vault count.
    function vaultCount() external view returns (uint256) {
        return _vaults.length();
    }    

    /// @dev Get the adapter of a vault.
    ///
    /// @param _vaultId the identifier of the vault.
    ///
    /// @return the vault adapter.
    function getVaultAdapter(uint256 _vaultId) external view returns (IVaultAdapter) {
        Vault.Data storage _vault = _vaults.get(_vaultId);
        return _vault.adapter;
    }

    /// @dev Get the total amount of the parent asset that has been deposited into a vault.
    ///
    /// @param _vaultId the identifier of the vault.
    ///
    /// @return the total amount of deposited tokens.
    function getVaultTotalDeposited(uint256 _vaultId) external view returns (uint256) {
        Vault.Data storage _vault = _vaults.get(_vaultId);
        return _vault.totalDeposited;
    }

    function getUserCDPData(address account) external view returns (CDPv2.Data memory) {
        CDPv2.Data storage _cdp = _cdps[account];
        return _cdp;
    }

    function getAccruedInterest(address account) external view returns (uint256) {
        CDPv2.Data storage _cdp = _cdps[account];

        uint256 _earnedYield = _cdp.getEarnedYield(_ctx);
        return _cdp.totalCredit.add(_earnedYield);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

//import "hardhat/console.sol";

import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IDetailedERC20} from "../../interfaces/IDetailedERC20.sol";
import {IVaultAdapter} from "../../interfaces/IVaultAdapter.sol";
import "hardhat/console.sol";

/// @title Pool
///
/// @dev A library which provides the Vault data struct and associated functions.
library Vault {
  using Vault for Data;
  using Vault for List;
  using SafeERC20 for IDetailedERC20;
  using SafeMath for uint256;

  struct Data {
    IVaultAdapter adapter;
    uint256 totalDeposited;
  }

  struct List {
    Data[] elements;
  }

  /// @dev Gets the total amount of assets deposited in the vault.
  ///
  /// @return the total assets.
  function totalValue(Data storage _self) internal view returns (uint256) {
    return _self.adapter.totalValue();
  }

  /// @dev Gets the total vault yield.
  ///
  /// @return the total yield.
  function totalYield(Data storage _self) internal view returns (uint256) {
    return _self.totalValue().sub(_self.totalDeposited);
  }

  /// @dev Gets the token that the vault accepts.
  ///
  /// @return the accepted token.
  function token(Data storage _self) internal view returns (IDetailedERC20) {
    return IDetailedERC20(_self.adapter.token());
  }

  /// @dev Deposits funds from the caller into the vault.
  ///
  /// @param _amount the amount of funds to deposit.
  function deposit(Data storage _self, uint256 _amount) internal returns (uint256) {
    // Push the token that the vault accepts onto the stack to save gas.
    IDetailedERC20 _token = _self.token();

    _token.safeTransfer(address(_self.adapter), _amount);
    _self.adapter.deposit(_amount);
    _self.totalDeposited = _self.totalDeposited.add(_amount);

    return _amount;
  }

  /// @dev Deposits the entire token balance of the caller into the vault.
  function depositAll(Data storage _self) internal returns (uint256) {
    IDetailedERC20 _token = _self.token();
    return _self.deposit(_token.balanceOf(address(this)));
  }

  /// @dev Withdraw deposited funds from the vault.
  ///
  /// @param _recipient the account to withdraw the tokens to.
  /// @param _amount    the amount of tokens to withdraw.
  function withdraw(Data storage _self, address _recipient, uint256 _amount) internal returns (uint256, uint256) {
    (uint256 _withdrawnAmount, uint256 _decreasedValue) = _self.directWithdraw(_recipient, _amount);
    _self.totalDeposited = _self.totalDeposited.sub(_decreasedValue);
    return (_withdrawnAmount, _decreasedValue);
  }

  /// @dev Directly withdraw deposited funds from the vault.
  ///
  /// @param _recipient the account to withdraw the tokens to.
  /// @param _amount    the amount of tokens to withdraw.
  function directWithdraw(Data storage _self, address _recipient, uint256 _amount) internal returns (uint256, uint256) {
    IDetailedERC20 _token = _self.token();

    uint256 _startingBalance = _token.balanceOf(_recipient);
    uint256 _startingTotalValue = _self.totalValue();

    _self.adapter.withdraw(_recipient, _amount);

    uint256 _endingBalance = _token.balanceOf(_recipient);
    uint256 _withdrawnAmount = _endingBalance.sub(_startingBalance);

    uint256 _endingTotalValue = _self.totalValue();
    uint256 _decreasedValue = _startingTotalValue.sub(_endingTotalValue);

    return (_withdrawnAmount, _decreasedValue);
  }

  /// @dev Withdraw all the deposited funds from the vault.
  ///
  /// @param _recipient the account to withdraw the tokens to.
  function withdrawAll(Data storage _self, address _recipient) internal returns (uint256, uint256) {
    return _self.withdraw(_recipient, _self.totalDeposited);
  }

  /// @dev Harvests yield from the vault.
  ///
  /// @param _recipient the account to withdraw the harvested yield to.
  function harvest(Data storage _self, address _recipient) internal returns (uint256, uint256) {
    if (_self.totalValue() <= _self.totalDeposited) {
      return (0, 0);
    }
    uint256 _withdrawAmount = _self.totalValue().sub(_self.totalDeposited);
    return _self.directWithdraw(_recipient, _withdrawAmount);
  }

  /// @dev Adds a element to the list.
  ///
  /// @param _element the element to add.
  function push(List storage _self, Data memory _element) internal {
    _self.elements.push(_element);
  }

  /// @dev Gets a element from the list.
  ///
  /// @param _index the index in the list.
  ///
  /// @return the element at the specified index.
  function get(List storage _self, uint256 _index) internal view returns (Data storage) {
    return _self.elements[_index];
  }

  /// @dev Gets the last element in the list.
  ///
  /// This function will revert if there are no elements in the list.
  ///
  /// @return the last element in the list.
  function last(List storage _self) internal view returns (Data storage) {
    return _self.elements[_self.lastIndex()];
  }

  /// @dev Gets the index of the last element in the list.
  ///
  /// This function will revert if there are no elements in the list.
  ///
  /// @return the index of the last element.
  function lastIndex(List storage _self) internal view returns (uint256) {
    uint256 _length = _self.length();
    return _length.sub(1, "Vault.List: empty");
  }

  /// @dev Gets the number of elements in the list.
  ///
  /// @return the number of elements.
  function length(List storage _self) internal view returns (uint256) {
    return _self.elements.length;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IERC20Burnable.sol";

import "hardhat/console.sol";

/**
 * @dev Implementation of the {IERC20Burnable} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20Burnable-approve}.
 */
contract Transmuter is Context {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Burnable;
    using Address for address;

    address public constant ZERO_ADDRESS = address(0);
    uint256 public TRANSMUTATION_PERIOD;

    address public GsAuxToken;
    address public AuxToken;

    mapping(address => uint256) public depositedGsAuxTokens;
    mapping(address => uint256) public tokensInBucket;
    mapping(address => uint256) public realisedTokens;
    mapping(address => uint256) public lastDividendPoints;

    mapping(address => bool) public userIsKnown;
    mapping(uint256 => address) public userList;
    uint256 public nextUser;

    uint256 public totalSupplyGsAuxtokens;
    uint256 public buffer;
    uint256 public lastDepositBlock; // Set to equal block timestamp in AVAX network.

    ///@dev values needed to calculate the distribution of base asset in proportion for gsAuxTokens staked
    uint256 public constant pointMultiplier = 1e18;

    uint256 public totalDividendPoints;
    uint256 public unclaimedDividends;

    /// @dev alchemist addresses whitelisted
    mapping(address => bool) public whiteList;

    /// @dev The address of the account which currently has administrative capabilities over this contract.
    address public governance;

    /// @dev The address of the pending governance.
    address public pendingGovernance;

    event GovernanceUpdated(address governance);

    event PendingGovernanceUpdated(address pendingGovernance);

    event TransmuterPeriodUpdated(uint256 newTransmutationPeriod);

    event Whitelisted(address account, bool status);

    constructor(address _GsAuxToken, address _AuxToken, address _governance) public {
        require(_GsAuxToken != ZERO_ADDRESS, "Error: Cannot be the null address");
        require(_AuxToken != ZERO_ADDRESS, "Error: Cannot be the null address");
        require(_governance != ZERO_ADDRESS, "Error: Cannot be the null address");

        GsAuxToken = _GsAuxToken;
        AuxToken = _AuxToken;
        governance = _governance;

        TRANSMUTATION_PERIOD = 900; // In seconds, equals 15 minutes.
    }

    ///@return displays the user's share of the pooled gsAuxTokens.
    function dividendsOwing(address account) public view returns (uint256) {
        uint256 newDividendPoints = totalDividendPoints.sub(
            lastDividendPoints[account]
        );
        return
            depositedGsAuxTokens[account].mul(newDividendPoints).div(
                pointMultiplier
            );
    }

    ///@dev modifier to fill the bucket and keep bookkeeping correct incase of increase/decrease in shares
    modifier updateAccount(address account) {
        uint256 owing = dividendsOwing(account);
        if (owing > 0) {
            unclaimedDividends = unclaimedDividends.sub(owing);
            tokensInBucket[account] = tokensInBucket[account].add(owing);
        }
        lastDividendPoints[account] = totalDividendPoints;
        _;
    }
    
    ///@dev modifier add users to userlist. Users are indexed in order to keep track of when a bond has been filled
    modifier checkIfNewUser() {
        if (!userIsKnown[msg.sender]) {
            userList[nextUser] = msg.sender;
            userIsKnown[msg.sender] = true;
            nextUser++;
        }
        _;
    }

    ///@dev run the phased distribution of the buffered funds
    modifier runPhasedDistribution() {
        uint256 _lastDepositBlock = lastDepositBlock;
        uint256 _currentBlock = block.timestamp;
        uint256 _toDistribute = 0;
        uint256 _buffer = buffer;

        // check if there is something in bufffer
        if (_buffer > 0) {
            // NOTE: if last deposit was updated in the same block as the current call
            // then the below logic gates will fail

            //calculate diffrence in time
            uint256 deltaTime = _currentBlock.sub(_lastDepositBlock);

            // distribute all if bigger than timeframe
            if (deltaTime >= TRANSMUTATION_PERIOD) {
                //console.log("Option A");
                _toDistribute = _buffer;
            } else {
                //needs to be bigger than 0 cuzz solidity no decimals
                if (_buffer.mul(deltaTime) > TRANSMUTATION_PERIOD) {
                    //console.log("Option B");
                    _toDistribute = _buffer.mul(deltaTime).div(
                        TRANSMUTATION_PERIOD
                    );
                }
            }
            //console.log("To Distribute:", _toDistribute);

            // factually allocate if any needs distribution
            if (_toDistribute > 0) {
                // remove from buffer
                buffer = _buffer.sub(_toDistribute);
                //console.log("Buffer after substraction:", buffer);
                // increase the allocation
                increaseAllocations(_toDistribute);
            }
        }

        // current timeframe is now the last
        lastDepositBlock = _currentBlock;
        _;
    }

    /// @dev A modifier which checks if whitelisted for minting.
    modifier onlyWhitelisted() {
        require(whiteList[msg.sender], "Transmuter: !whitelisted");
        _;
    }

    /// @dev Checks that the current message sender or caller is the governance address.
    ///
    ///
    modifier onlyGov() {
        require(msg.sender == governance, "Transmuter: !governance");
        _;
    }

    ///@dev set the TRANSMUTATION_PERIOD variable
    ///
    /// sets the length (in blocks) of one full distribution phase
    /// NoteAugusto: for avax network, the length is set in number of seconds.
    function setTransmutationPeriod(uint256 newTransmutationPeriod) external onlyGov {
        TRANSMUTATION_PERIOD = newTransmutationPeriod;
        emit TransmuterPeriodUpdated(TRANSMUTATION_PERIOD);
    }

    ///@dev claims the base token after it has been transmuted
    ///
    ///This function reverts if there is no realisedToken balance
    function claim() public {
        address sender = msg.sender;
        require(realisedTokens[sender] > 0, "Error: Null realized tokens");
        uint256 value = realisedTokens[sender];
        realisedTokens[sender] = 0;
        IERC20Burnable(AuxToken).safeTransfer(sender, value);
    }

    ///@dev Withdraws staked gsAuxTokens from the transmuter
    ///
    /// This function reverts if you try to draw more tokens than you deposited
    ///
    ///@param amount the amount of gsAuxTokens to unstake
    function unstake(uint256 amount) public updateAccount(msg.sender) {
        // by calling this function before transmuting you forfeit your gained allocation
        address sender = msg.sender;
        require(
            depositedGsAuxTokens[sender] >= amount,
            "Transmuter: unstake amount exceeds deposited amount"
        );
        depositedGsAuxTokens[sender] = depositedGsAuxTokens[sender].sub(amount);
        totalSupplyGsAuxtokens = totalSupplyGsAuxtokens.sub(amount);
        IERC20Burnable(GsAuxToken).safeTransfer(sender, amount);
    }

    ///@dev Deposits gsAuxTokens into the transmuter
    ///
    ///@param amount the amount of gsAuxTokens to stake
    function stake(uint256 amount) external runPhasedDistribution updateAccount(msg.sender) checkIfNewUser {
        // requires approval of GsAuxToken first
        address sender = msg.sender;
        //require tokens transferred in;
        IERC20Burnable(GsAuxToken).safeTransferFrom(
            sender,
            address(this),
            amount
        );
        totalSupplyGsAuxtokens = totalSupplyGsAuxtokens.add(amount);
        depositedGsAuxTokens[sender] = depositedGsAuxTokens[sender].add(amount);
    }

    /// @dev Converts the staked gsAuxTokens to the base tokens in amount of the sum of pendingdivs and tokensInBucket
    ///
    /// once the gsAuxToken has been converted, it is burned, and the base token becomes realisedTokens which can be recieved using claim()
    ///
    /// reverts if there are no pendingdivs or tokensInBucket
    function transmute() public runPhasedDistribution updateAccount(msg.sender) {
        address sender = msg.sender;
        uint256 pendingz = tokensInBucket[sender];
        //console.log(pendingz);
        uint256 diff;

        require(pendingz > 0, "Error: Need to have pending in bucket");

        tokensInBucket[sender] = 0;

        // check bucket overflow
        if (pendingz > depositedGsAuxTokens[sender]) {
            diff = pendingz.sub(depositedGsAuxTokens[sender]);

            // remove overflow
            pendingz = depositedGsAuxTokens[sender];
        }

        // decrease altokens
        depositedGsAuxTokens[sender] = depositedGsAuxTokens[sender].sub(
            pendingz
        );

        // BURN ALTOKENS
        IERC20Burnable(GsAuxToken).burn(pendingz);

        // adjust total
        totalSupplyGsAuxtokens = totalSupplyGsAuxtokens.sub(pendingz);

        // reallocate overflow
        increaseAllocations(diff);

        // add payout
        realisedTokens[sender] = realisedTokens[sender].add(pendingz);
    }

    /// @dev Executes transmute() on another account that has had more base tokens allocated to it than gsAuxTokens staked.
    ///
    /// The caller of this function will have the surplus base tokens credited to their tokensInBucket balance, rewarding them for performing this action
    ///
    /// This function reverts if the address to transmute is not over-filled.
    ///
    /// @param toTransmute address of the account you will force transmute.
    function forceTransmute(address toTransmute) public runPhasedDistribution updateAccount(msg.sender) updateAccount(toTransmute) {
        //load into memory
        address sender = msg.sender;
        uint256 pendingz = tokensInBucket[toTransmute];
        // check restrictions
        require(
            pendingz > depositedGsAuxTokens[toTransmute],
            "Transmuter: !overflow"
        );

        // empty bucket
        tokensInBucket[toTransmute] = 0;

        // calculaate diffrence
        uint256 diff = pendingz.sub(depositedGsAuxTokens[toTransmute]);

        // remove overflow
        pendingz = depositedGsAuxTokens[toTransmute];

        // decrease altokens
        depositedGsAuxTokens[toTransmute] = 0;

        // BURN ALTOKENS
        IERC20Burnable(GsAuxToken).burn(pendingz);

        // adjust total
        totalSupplyGsAuxtokens = totalSupplyGsAuxtokens.sub(pendingz);

        // reallocate overflow
        tokensInBucket[sender] = tokensInBucket[sender].add(diff);

        // add payout
        realisedTokens[toTransmute] = realisedTokens[toTransmute].add(pendingz);

        // force payout of realised tokens of the toTransmute address
        if (realisedTokens[toTransmute] > 0) {
            uint256 value = realisedTokens[toTransmute];
            realisedTokens[toTransmute] = 0;
            IERC20Burnable(AuxToken).safeTransfer(toTransmute, value);
        }
    }

    /// @dev Transmutes and unstakes all gsAuxTokens
    ///
    /// This function combines the transmute and unstake functions for ease of use
    /// Do not recommend usage since it implies forfeit of accrued base tokens.
    function exit() public {
        transmute();
        uint256 toWithdraw = depositedGsAuxTokens[msg.sender];
        unstake(toWithdraw);
    }

    /// @dev Transmutes and claims all converted base tokens.
    ///
    /// This function combines the transmute and claim functions while leaving your remaining gsAuxTokens staked.
    function transmuteAndClaim() public {
        transmute();
        claim();
    }

    /// @dev Transmutes, claims base tokens, and withdraws gsAuxTokens.
    ///
    /// This function helps users to exit the transmuter contract completely after converting their gsAuxTokens to the base pair.
    function transmuteClaimAndWithdraw() public {
        transmute();
        claim();
        uint256 toWithdraw = depositedGsAuxTokens[msg.sender];
        unstake(toWithdraw);
    }

    /// @dev Distributes the base token proportionally to all gsAuxToken stakers.
    ///
    /// This function is meant to be called by the Alchemist contract for when it is sending yield to the transmuter.
    /// Anyone can call this and add funds, idk why they would do that though...
    ///
    /// @param origin the account that is sending the tokens to be distributed.
    /// @param amount the amount of base tokens to be distributed to the transmuter.
    function distribute(address origin, uint256 amount) public onlyWhitelisted runPhasedDistribution {
        IERC20Burnable(AuxToken).safeTransferFrom(
            origin,
            address(this),
            amount
        );
        buffer = buffer.add(amount);
    }

    /// @dev Allocates the incoming yield proportionally to all gsAuxToken stakers.
    ///
    /// @param amount the amount of base tokens to be distributed in the transmuter.
    function increaseAllocations(uint256 amount) internal {
        //console.log("Increasing allocation");
        if (totalSupplyGsAuxtokens > 0 && amount > 0) {
            //console.log("Total supply gsAUX tokens:", totalSupplyGsAuxtokens);
            //console.log("AUX amount:", amount);
            //console.log("Point multiplier:", pointMultiplier);
            totalDividendPoints = totalDividendPoints.add(
                amount.mul(pointMultiplier).div(totalSupplyGsAuxtokens)
            );
            unclaimedDividends = unclaimedDividends.add(amount);
        } else {
            buffer = buffer.add(amount);
            //console.log("New buffer value is:", buffer);
        }
    }

    /// @dev Gets the status of a user's staking position.
    ///
    /// The total amount allocated to a user is the sum of pendingdivs and inbucket.
    ///
    /// @param user the address of the user you wish to query.
    ///
    /// returns user status

    function userInfo(address user)
        public
        view
        returns (
            uint256 depositedGsAux,
            uint256 pendingdivs,
            uint256 inbucket,
            uint256 realised
        )
    {
        uint256 _depositedGsAux = depositedGsAuxTokens[user];
        uint256 _toDistribute = buffer
            .mul(block.timestamp.sub(lastDepositBlock))
            .div(TRANSMUTATION_PERIOD);
        if (block.timestamp.sub(lastDepositBlock) > TRANSMUTATION_PERIOD) {
            _toDistribute = buffer;
        }
        //console.log("ToDistribute is:", _toDistribute);
        uint256 _pendingdivs = _toDistribute
            .mul(depositedGsAuxTokens[user])
            .div(totalSupplyGsAuxtokens);
        uint256 _inbucket = tokensInBucket[user].add(dividendsOwing(user));
        uint256 _realised = realisedTokens[user];
        return (_depositedGsAux, _pendingdivs, _inbucket, _realised);
    }

    /// @dev Gets the status of multiple users in one call
    ///
    /// This function is used to query the contract to check for
    /// accounts that have overfilled positions in order to check
    /// who can be force transmuted.
    ///
    /// @param from the first index of the userList
    /// @param to the last index of the userList
    ///
    /// returns the userList with their staking status in paginated form.
    function getMultipleUserInfo(uint256 from, uint256 to)
        public
        view
        returns (address[] memory theUserList, uint256[] memory theUserData)
    {
        uint256 i = from;
        uint256 delta = to - from;
        address[] memory _theUserList = new address[](delta); //user
        uint256[] memory _theUserData = new uint256[](delta * 2); //deposited-bucket
        uint256 y = 0;
        uint256 _toDistribute = buffer
            .mul(block.timestamp.sub(lastDepositBlock))
            .div(TRANSMUTATION_PERIOD);
        if (block.timestamp.sub(lastDepositBlock) > TRANSMUTATION_PERIOD) {
            _toDistribute = buffer;
        }
        for (uint256 x = 0; x < delta; x += 1) {
            _theUserList[x] = userList[i];
            _theUserData[y] = depositedGsAuxTokens[userList[i]];
            _theUserData[y + 1] = dividendsOwing(userList[i])
                .add(tokensInBucket[userList[i]])
                .add(
                    _toDistribute.mul(depositedGsAuxTokens[userList[i]]).div(
                        totalSupplyGsAuxtokens
                    )
                );
            y += 2;
            i += 1;
        }
        return (_theUserList, _theUserData);
    }

    /// @dev Gets info on the buffer
    ///
    /// This function is used to query the contract to get the
    /// latest state of the buffer
    ///
    /// @return _toDistribute the amount ready to be distributed
    /// @return _deltaBlocks the amount of time since the last phased distribution
    /// @return _buffer the amount in the buffer
    function bufferInfo()
        public
        view
        returns (
            uint256 _toDistribute,
            uint256 _deltaBlocks,
            uint256 _buffer
        )
    {
        _deltaBlocks = block.timestamp.sub(lastDepositBlock);
        _buffer = buffer;
        _toDistribute = _buffer.mul(_deltaBlocks).div(TRANSMUTATION_PERIOD);
    }

    /// @dev Sets the pending governance.
    ///
    /// This function reverts if the new pending governance is the zero address or the caller is not the current
    /// governance. This is to prevent the contract governance being set to the zero address which would deadlock
    /// privileged contract functionality.
    ///
    /// @param _pendingGovernance the new pending governance.
    function setPendingGovernance(address _pendingGovernance) external onlyGov {
        require(_pendingGovernance != ZERO_ADDRESS, "Error: Cannot be the null address");

        pendingGovernance = _pendingGovernance;

        emit PendingGovernanceUpdated(_pendingGovernance);
    }

    /// @dev Accepts the role as governance.
    ///
    /// This function reverts if the caller is not the new pending governance.
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "Error: Not pendingGovernance");

        governance = pendingGovernance;
        pendingGovernance = ZERO_ADDRESS;

        emit GovernanceUpdated(governance);
    }

    /// This function reverts if the caller is not governance
    ///
    /// @param _toWhitelist the account to mint tokens to.
    /// @param _state the whitelist state.

    function setWhitelist(address _toWhitelist, bool _state) external onlyGov {
        require(_toWhitelist != address(0), "Error: Cannot be the null address");
        whiteList[_toWhitelist] = _state;

        emit Whitelisted(_toWhitelist, _state);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Burnable is IERC20 {
  function burn(uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IERC20Burnable.sol";

import "hardhat/console.sol";

/**
 * @dev Implementation of the {IERC20Burnable} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20Burnable-approve}.
 */
contract TransmuterMock is Context {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Burnable;
    using Address for address;

    address public constant ZERO_ADDRESS = address(0);
    uint256 public TRANSMUTATION_PERIOD;

    address public GsAuxToken;
    address public AuxToken;

    mapping(address => uint256) public depositedGsAuxTokens;
    mapping(address => uint256) public tokensInBucket;
    mapping(address => uint256) public realisedTokens;
    mapping(address => uint256) public lastDividendPoints;

    mapping(address => bool) public userIsKnown;
    mapping(uint256 => address) public userList;
    uint256 public nextUser;

    uint256 public totalSupplyGsAuxtokens;
    uint256 public buffer;
    uint256 public lastDepositBlock;

    ///@dev values needed to calculate the distribution of base asset in proportion for gsAuxTokens staked
    uint256 public pointMultiplier = 10e18;

    uint256 public totalDividendPoints;
    uint256 public unclaimedDividends;

    /// @dev alchemist addresses whitelisted
    mapping(address => bool) public whiteList;

    /// @dev The address of the account which currently has administrative capabilities over this contract.
    address public governance;

    /// @dev The address of the pending governance.
    address public pendingGovernance;

    event GovernanceUpdated(address governance);

    event PendingGovernanceUpdated(address pendingGovernance);

    event TransmuterPeriodUpdated(uint256 newTransmutationPeriod);

    constructor(
        address _GsAuxToken,
        address _AuxToken,
        address _governance
    ) public {
        require(_governance != ZERO_ADDRESS, "Transmuter: 0 gov");
        governance = _governance;
        GsAuxToken = _GsAuxToken;
        AuxToken = _AuxToken;
        TRANSMUTATION_PERIOD = 900; // In seconds, equals 15 minutes.
    }

    ///@return displays the user's share of the pooled gsAuxTokens.
    function dividendsOwing(address account) public view returns (uint256) {
        uint256 newDividendPoints = totalDividendPoints.sub(
            lastDividendPoints[account]
        );
        return
            depositedGsAuxTokens[account].mul(newDividendPoints).div(
                pointMultiplier
            );
    }

    ///@dev modifier to fill the bucket and keep bookkeeping correct incase of increase/decrease in shares
    modifier updateAccount(address account) {
        uint256 owing = dividendsOwing(account);
        if (owing > 0) {
            unclaimedDividends = unclaimedDividends.sub(owing);
            tokensInBucket[account] = tokensInBucket[account].add(owing);
        }
        lastDividendPoints[account] = totalDividendPoints;
        _;
    }
    ///@dev modifier add users to userlist. Users are indexed in order to keep track of when a bond has been filled
    modifier checkIfNewUser() {
        if (!userIsKnown[msg.sender]) {
            userList[nextUser] = msg.sender;
            userIsKnown[msg.sender] = true;
            nextUser++;
        }
        _;
    }

    ///@dev run the phased distribution of the buffered funds
    modifier runPhasedDistribution() {
        uint256 _lastDepositBlock = lastDepositBlock;
        uint256 _currentBlock = block.timestamp;
        uint256 _toDistribute = 0;
        uint256 _buffer = buffer;

        // check if there is something in bufffer
        if (_buffer > 0) {
            // NOTE: if last deposit was updated in the same block as the current call
            // then the below logic gates will fail

            //calculate diffrence in time
            uint256 deltaTime = _currentBlock.sub(_lastDepositBlock);

            // distribute all if bigger than timeframe
            if (deltaTime >= TRANSMUTATION_PERIOD) {
                _toDistribute = _buffer;
            } else {
                //needs to be bigger than 0 cuzz solidity no decimals
                if (_buffer.mul(deltaTime) > TRANSMUTATION_PERIOD) {
                    _toDistribute = _buffer.mul(deltaTime).div(
                        TRANSMUTATION_PERIOD
                    );
                }
            }

            // factually allocate if any needs distribution
            if (_toDistribute > 0) {
                // remove from buffer
                buffer = _buffer.sub(_toDistribute);

                // increase the allocation
                increaseAllocations(_toDistribute);
            }
        }

        // current timeframe is now the last
        lastDepositBlock = _currentBlock;
        _;
    }

    /// @dev A modifier which checks if whitelisted for minting.
    modifier onlyWhitelisted() {
        require(whiteList[msg.sender], "Transmuter: !whitelisted");
        _;
    }

    /// @dev Checks that the current message sender or caller is the governance address.
    ///
    ///
    modifier onlyGov() {
        require(msg.sender == governance, "Transmuter: !governance");
        _;
    }

    ///@dev set the TRANSMUTATION_PERIOD variable
    ///
    /// sets the length (in blocks) of one full distribution phase
    /// NoteAugusto: for avax network, the length is set in number of seconds.
    function setTransmutationPeriod(uint256 newTransmutationPeriod)
        public
    {
        TRANSMUTATION_PERIOD = newTransmutationPeriod;
        emit TransmuterPeriodUpdated(TRANSMUTATION_PERIOD);
    }

    ///@dev claims the base token after it has been transmuted
    ///
    ///This function reverts if there is no realisedToken balance
    function claim() public {
        address sender = msg.sender;
        require(realisedTokens[sender] > 0);
        uint256 value = realisedTokens[sender];
        realisedTokens[sender] = 0;
        IERC20Burnable(AuxToken).safeTransfer(sender, value);
    }

    ///@dev auto claims the base token after it has been transmuted to sender address
    ///
    ///This function reverts if there is no realisedToken balance
    function autoClaim(address sender) public returns(uint256 value) {
        value = realisedTokens[sender];
        require(value > 0);
        realisedTokens[sender] = 0;
    }

    ///@dev Withdraws staked gsAuxTokens from the transmuter
    ///
    /// This function reverts if you try to draw more tokens than you deposited
    ///
    ///@param amount the amount of gsAuxTokens to unstake
    function unstake(uint256 amount) public updateAccount(msg.sender) {
        // by calling this function before transmuting you forfeit your gained allocation
        address sender = msg.sender;
        require(
            depositedGsAuxTokens[sender] >= amount,
            "Transmuter: unstake amount exceeds deposited amount"
        );
        depositedGsAuxTokens[sender] = depositedGsAuxTokens[sender].sub(amount);
        totalSupplyGsAuxtokens = totalSupplyGsAuxtokens.sub(amount);
        IERC20Burnable(GsAuxToken).safeTransfer(sender, amount);
    }

    ///@dev Deposits gsAuxTokens into the transmuter
    ///
    ///@param amount the amount of gsAuxTokens to stake
    function stake(uint256 amount)
        public
        runPhasedDistribution
        updateAccount(msg.sender)
        checkIfNewUser
    {
        // requires approval of GsAuxToken first
        address sender = msg.sender;
        //require tokens transferred in;
        IERC20Burnable(GsAuxToken).safeTransferFrom(
            sender,
            address(this),
            amount
        );
        totalSupplyGsAuxtokens = totalSupplyGsAuxtokens.add(amount);
        depositedGsAuxTokens[sender] = depositedGsAuxTokens[sender].add(amount);
    }

    /// @dev Converts the staked gsAuxTokens to the base tokens in amount of the sum of pendingdivs and tokensInBucket
    ///
    /// once the gsAuxToken has been converted, it is burned, and the base token becomes realisedTokens which can be recieved using claim()
    ///
    /// reverts if there are no pendingdivs or tokensInBucket
    function transmute()
        public
        runPhasedDistribution
        updateAccount(msg.sender)
    {
        address sender = msg.sender;
        uint256 pendingz = tokensInBucket[sender];
        uint256 diff;

        require(pendingz > 0, "need to have pending in bucket");

        tokensInBucket[sender] = 0;

        // check bucket overflow
        if (pendingz > depositedGsAuxTokens[sender]) {
            diff = pendingz.sub(depositedGsAuxTokens[sender]);

            // remove overflow
            pendingz = depositedGsAuxTokens[sender];
        }

        // decrease altokens
        depositedGsAuxTokens[sender] = depositedGsAuxTokens[sender].sub(
            pendingz
        );

        // BURN ALTOKENS
        IERC20Burnable(GsAuxToken).burn(pendingz);

        // adjust total
        totalSupplyGsAuxtokens = totalSupplyGsAuxtokens.sub(pendingz);

        // reallocate overflow
        increaseAllocations(diff);

        // add payout
        realisedTokens[sender] = realisedTokens[sender].add(pendingz);
    }

    /// @dev Executes transmute() on another account that has had more base tokens allocated to it than gsAuxTokens staked.
    ///
    /// The caller of this function will have the surlus base tokens credited to their tokensInBucket balance, rewarding them for performing this action
    ///
    /// This function reverts if the address to transmute is not over-filled.
    ///
    /// @param toTransmute address of the account you will force transmute.
    function forceTransmute(address toTransmute)
        public
        runPhasedDistribution
        updateAccount(msg.sender)
        updateAccount(toTransmute)
    {
        //load into memory
        address sender = msg.sender;
        uint256 pendingz = tokensInBucket[toTransmute];
        // check restrictions
        require(
            pendingz > depositedGsAuxTokens[toTransmute],
            "Transmuter: !overflow"
        );

        // empty bucket
        tokensInBucket[toTransmute] = 0;

        // calculaate diffrence
        uint256 diff = pendingz.sub(depositedGsAuxTokens[toTransmute]);

        // remove overflow
        pendingz = depositedGsAuxTokens[toTransmute];

        // decrease altokens
        depositedGsAuxTokens[toTransmute] = 0;

        // BURN ALTOKENS
        IERC20Burnable(GsAuxToken).burn(pendingz);

        // adjust total
        totalSupplyGsAuxtokens = totalSupplyGsAuxtokens.sub(pendingz);

        // reallocate overflow
        tokensInBucket[sender] = tokensInBucket[sender].add(diff);

        // add payout
        realisedTokens[toTransmute] = realisedTokens[toTransmute].add(pendingz);

        // force payout of realised tokens of the toTransmute address
        if (realisedTokens[toTransmute] > 0) {
            uint256 value = realisedTokens[toTransmute];
            realisedTokens[toTransmute] = 0;
            IERC20Burnable(AuxToken).safeTransfer(toTransmute, value);
        }
    }

    /// @dev Transmutes and unstakes all gsAuxTokens
    ///
    /// This function combines the transmute and unstake functions for ease of use
    function exit() public {
        transmute();
        uint256 toWithdraw = depositedGsAuxTokens[msg.sender];
        unstake(toWithdraw);
    }

    /// @dev Transmutes and claims all converted base tokens.
    ///
    /// This function combines the transmute and claim functions while leaving your remaining gsAuxTokens staked.
    function transmuteAndClaim() public {
        transmute();
        claim();
    }

    /// @dev Transmutes, claims base tokens, and withdraws gsAuxTokens.
    ///
    /// This function helps users to exit the transmuter contract completely after converting their gsAuxTokens to the base pair.
    function transmuteClaimAndWithdraw() public {
        transmute();
        claim();
        uint256 toWithdraw = depositedGsAuxTokens[msg.sender];
        unstake(toWithdraw);
    }

    /// @dev Distributes the base token proportionally to all gsAuxToken stakers.
    ///
    /// This function is meant to be called by the Alchemist contract for when it is sending yield to the transmuter.
    /// Anyone can call this and add funds, idk why they would do that though...
    ///
    /// @param origin the account that is sending the tokens to be distributed.
    /// @param amount the amount of base tokens to be distributed to the transmuter.
    function distribute(address origin, uint256 amount)
        public
        
        runPhasedDistribution
    {
        IERC20Burnable(AuxToken).safeTransferFrom(
            origin,
            address(this),
            amount
        );
        buffer = buffer.add(amount);
    }

    /// @dev Allocates the incoming yield proportionally to all gsAuxToken stakers.
    ///
    /// @param amount the amount of base tokens to be distributed in the transmuter.
    function increaseAllocations(uint256 amount) internal {
        if (totalSupplyGsAuxtokens > 0 && amount > 0) {
            totalDividendPoints = totalDividendPoints.add(
                amount.mul(pointMultiplier).div(totalSupplyGsAuxtokens)
            );
            unclaimedDividends = unclaimedDividends.add(amount);
        } else {
            buffer = buffer.add(amount);
        }
    }

    /// @dev Gets the status of a user's staking position.
    ///
    /// The total amount allocated to a user is the sum of pendingdivs and inbucket.
    ///
    /// @param user the address of the user you wish to query.
    ///
    /// returns user status

    function userInfo(address user)
        public
        view
        returns (
            uint256 depositedGsAux,
            uint256 pendingdivs,
            uint256 inbucket,
            uint256 realised
        )
    {
        uint256 _depositedGsAux = depositedGsAuxTokens[user];
        uint256 _toDistribute = buffer
            .mul(block.timestamp.sub(lastDepositBlock))
            .div(TRANSMUTATION_PERIOD);
        if (block.timestamp.sub(lastDepositBlock) > TRANSMUTATION_PERIOD) {
            _toDistribute = buffer;
        }
        uint256 _pendingdivs = _toDistribute
            .mul(depositedGsAuxTokens[user])
            .div(totalSupplyGsAuxtokens);
        uint256 _inbucket = tokensInBucket[user].add(dividendsOwing(user));
        uint256 _realised = realisedTokens[user];
        return (_depositedGsAux, _pendingdivs, _inbucket, _realised);
    }

    /// @dev Gets the status of multiple users in one call
    ///
    /// This function is used to query the contract to check for
    /// accounts that have overfilled positions in order to check
    /// who can be force transmuted.
    ///
    /// @param from the first index of the userList
    /// @param to the last index of the userList
    ///
    /// returns the userList with their staking status in paginated form.
    function getMultipleUserInfo(uint256 from, uint256 to)
        public
        view
        returns (address[] memory theUserList, uint256[] memory theUserData)
    {
        uint256 i = from;
        uint256 delta = to - from;
        address[] memory _theUserList = new address[](delta); //user
        uint256[] memory _theUserData = new uint256[](delta * 2); //deposited-bucket
        uint256 y = 0;
        uint256 _toDistribute = buffer
            .mul(block.timestamp.sub(lastDepositBlock))
            .div(TRANSMUTATION_PERIOD);
        if (block.timestamp.sub(lastDepositBlock) > TRANSMUTATION_PERIOD) {
            _toDistribute = buffer;
        }
        for (uint256 x = 0; x < delta; x += 1) {
            _theUserList[x] = userList[i];
            _theUserData[y] = depositedGsAuxTokens[userList[i]];
            _theUserData[y + 1] = dividendsOwing(userList[i])
                .add(tokensInBucket[userList[i]])
                .add(
                    _toDistribute.mul(depositedGsAuxTokens[userList[i]]).div(
                        totalSupplyGsAuxtokens
                    )
                );
            y += 2;
            i += 1;
        }
        return (_theUserList, _theUserData);
    }

    /// @dev Gets info on the buffer
    ///
    /// This function is used to query the contract to get the
    /// latest state of the buffer
    ///
    /// @return _toDistribute the amount ready to be distributed
    /// @return _deltaBlocks the amount of time since the last phased distribution
    /// @return _buffer the amount in the buffer
    function bufferInfo()
        public
        view
        returns (
            uint256 _toDistribute,
            uint256 _deltaBlocks,
            uint256 _buffer
        )
    {
        _deltaBlocks = block.timestamp.sub(lastDepositBlock);
        _buffer = buffer;
        _toDistribute = _buffer.mul(_deltaBlocks).div(TRANSMUTATION_PERIOD);
    }

    /// @dev Sets the pending governance.
    ///
    /// This function reverts if the new pending governance is the zero address or the caller is not the current
    /// governance. This is to prevent the contract governance being set to the zero address which would deadlock
    /// privileged contract functionality.
    ///
    /// @param _pendingGovernance the new pending governance.
    function setPendingGovernance(address _pendingGovernance) external  {
        require(_pendingGovernance != ZERO_ADDRESS, "Transmuter: 0 gov");

        pendingGovernance = _pendingGovernance;

        emit PendingGovernanceUpdated(_pendingGovernance);
    }

    /// @dev Accepts the role as governance.
    ///
    /// This function reverts if the caller is not the new pending governance.
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "!pendingGovernance");
        address _pendingGovernance = pendingGovernance;
        governance = _pendingGovernance;

        emit GovernanceUpdated(_pendingGovernance);
    }

    /// This function reverts if the caller is not governance
    ///
    /// @param _toWhitelist the account to mint tokens to.
    /// @param _state the whitelist state.

    function setWhitelist(address _toWhitelist, bool _state) external  {
        whiteList[_toWhitelist] = _state;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity = 0.6.12;
pragma experimental ABIEncoderV2;

//import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {CDP} from "./libraries/gsdlending/CDP.sol";
import {FixedPointMath} from "./libraries/FixedPointMath.sol";
import {ITransmuter} from "./interfaces/ITransmuter.sol";
import {IGsdStaking} from "./interfaces/IGsdStaking.sol";
import {IMintableERC20} from "./interfaces/IMintableERC20.sol";
import {IChainlink} from "./interfaces/IChainlink.sol";
import {IVaultAdapter} from "./interfaces/IVaultAdapter.sol";
import {Vault} from "./libraries/gsdlending/Vault.sol";

import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";
import {PriceOracle} from "./libraries/gsdlending/PriceOracle.sol";
import {PriceRouter} from "./libraries/gsdlending/PriceRouter.sol";
import {SyntheticRouter} from "./libraries/gsdlending/SyntheticRouter.sol";
import {SwapRouterLib} from "./libraries/sushiswap/SwapRouter.sol";

import "./interfaces/IUniswapV2Router02.sol";
import "hardhat/console.sol";

contract Lending is ReentrancyGuard {
    using CDP for CDP.Data;
    using PriceOracle for PriceOracle.Oracle;
    using PriceRouter for PriceRouter.Router;
    using SyntheticRouter for SyntheticRouter.Router;
    using FixedPointMath for FixedPointMath.FixedDecimal;
    using Vault for Vault.Data;
    using Vault for Vault.List;
    using SafeERC20 for IMintableERC20;
    using SafeMath for uint256;
    using Address for address;
    using SwapRouterLib for SwapRouterLib.State;

    address public constant ZERO_ADDRESS = address(0);

    /// @dev Resolution for all fixed point numeric parameters which represent percents. The resolution allows for a
    /// granularity of 0.01% increments.
    uint256 public constant PERCENT_RESOLUTION = 10000;

    /// @dev The minimum value that the collateralization limit can be set to by the governance. This is a safety rail
    /// to prevent the collateralization from being set to a value which breaks the system.
    ///
    /// This value is equal to 100%.
    ///
    /// IMPORTANT: This constant is a raw FixedPointMath.FixedDecimal value and assumes a resolution of 64 bits. If the
    ///            resolution for the FixedPointMath library changes this constant must change as well.
    uint256 public constant MINIMUM_COLLATERALIZATION_LIMIT = 1e18;

    /// @dev The maximum value that the collateralization limit can be set to by the governance. This is a safety rail
    /// to prevent the collateralization from being set to a value which breaks the system.
    ///
    /// This value is equal to 400%.
    ///
    /// IMPORTANT: This constant is a raw FixedPointMath.FixedDecimal value and assumes a resolution of 64 bits. If the
    ///            resolution for the FixedPointMath library changes this constant must change as well.
    uint256 public constant MAXIMUM_COLLATERALIZATION_LIMIT = 4e18;

    event GovernanceUpdated(address governance);

    event PendingGovernanceUpdated(address pendingGovernance);

    event SentinelUpdated(address sentinel);

    event TransmuterUpdated(address transmuter);

    event StakingUpdated(address stakingContract);

    event StakingFeeUpdated(uint256 stakingFee);

    event FlushActivatorUpdated(uint256 flushActivator);

    event AuxPriceRouterUpdated(address router);

    event gsAuxPriceRouterUpdated(address router);

    event RewardsUpdated(address treasury);

    event HarvestFeeUpdated(uint256 fee);

    event CollateralizationLimitUpdated(uint256 limit);

    event EmergencyExitUpdated(bool status);

    event ActiveVaultUpdated(IVaultAdapter indexed adapter);

    event FundsHarvested(uint256 withdrawnAmount, uint256 decreasedValue, uint256 realizedAux);

    event FundsRecalled(
        uint256 indexed vaultId,
        uint256 withdrawnAmount,
        uint256 decreasedValue
    );

    event FundsFlushed(uint256 amount);

    event TokensDeposited(address indexed account, uint256 amount);

    event RouterIsSet(address router);

    event TokensWithdrawn(
        address indexed account,
        uint256 requestedAmount,
        uint256 withdrawnAmount,
        uint256 decreasedValue
    );

    event TokensRepaid(
        address indexed account,
        uint256 parentAmount,
        uint256 childAmount
    );

    event AutoRepaidTokens(
        address indexed account,
        uint256 auxAmount,
        uint256 usdValue
    );

    event TokensLiquidated(
        address indexed account,
        uint256 requestedAmount,
        uint256 withdrawnAmount,
        uint256 decreasedValue
    );

    /// @dev sushiswap lib.
    SwapRouterLib.State public SwapRouter;

    /// @dev Chainlink price oracle for AUXUSDC.
    PriceOracle.Oracle public _oracle;

    PriceRouter.Router public _router;
    
    SyntheticRouter.Router public _gsauxrouter;

    /// @dev usdc token.
    IMintableERC20 public usdcToken;

    /// @dev gsAux token.
    IMintableERC20 public gsAuxToken;

    /// @dev aux token.
    IMintableERC20 public auxToken;

    /// @dev The address of the account which currently has administrative capabilities over this contract.
    address public governance;

    /// @dev The address of the pending governance.
    address public pendingGovernance;

    /// @dev The address of the account which can initiate an emergency withdraw of funds in a vault.
    address public sentinel;

    /// @dev The address of the contract which will transmute synthetic tokens back into native tokens.
    address public transmuter;

    /// @dev The address of the staking contract to receive aux for GSD staking rewards.
    address public staking;

    /// @dev The percent of each profitable harvest that will go to the staking contract.
    uint256 public stakingFee;

    /// @dev The address of the contract which will receive fees.
    address public rewards;

    /// @dev The percent of each profitable harvest that will go to the rewards contract.
    uint256 public harvestFee;

    /// @dev The total amount of usdc in aux terms deposited into the system that is owned by external users.
    uint256 public totalDeposited; // Do we need this?


    /// @dev The total amount the native token deposited into the system that is owned by external users.
    uint256 public totalDepositedUsdc;

    /// @dev The total amount of gold loan given to users.
    uint256 public totalDebt;

    /// @dev when movemetns are bigger than this number flush is activated.
    uint256 public flushActivator;

    /// @dev A flag indicating if the contract has been initialized yet.
    bool public initialized;

    /// @dev A flag indicating if deposits and flushes should be halted and if all parties should be able to recall
    /// from the active vault.
    bool public emergencyExit;

    /// @dev The context shared between the CDPs.
    CDP.Context private _ctx;

    /// @dev A mapping of all of the user CDPs. If a user wishes to have multiple CDPs they will have to either
    /// create a new address or set up a proxy contract that interfaces with this contract.
    mapping(address => CDP.Data) private _cdps;

    /// @dev A list of all of the vaults. The last element of the list is the vault that is currently being used for
    /// deposits and withdraws. Vaults before the last element are considered inactive and are expected to be cleared.
    Vault.List private _vaults;

    /// @dev The address of the link oracle.
    /// NoteAugusto: we should check this variable as well as pegMinium usage.
    address public _linkGasOracle;

    /// @dev The minimum returned amount needed to be on peg according to the oracle.
    /// NoteAcarulo: we'll use this variable for the gsAUX/AUX pair. Set it at 90%.
    uint256 public pegMinimum;

    constructor(IMintableERC20 _usdctoken, IMintableERC20 _gsauxToken, IMintableERC20 _auxtoken, address _governance, address _sentinel) public {
        require(_governance != ZERO_ADDRESS, "Error: Cannot be the null address");
        require(_sentinel != ZERO_ADDRESS, "Error: Cannot be the null address");

        usdcToken = _usdctoken;
        gsAuxToken = _gsauxToken;
        auxToken = _auxtoken;

        sentinel = _sentinel;
        governance = _governance;
        flushActivator = 10000 * 1e6; // Ten thousand

        uint256 COLL_LIMIT = MINIMUM_COLLATERALIZATION_LIMIT.mul(2);
        _ctx.collateralizationLimit = FixedPointMath.FixedDecimal(COLL_LIMIT);
        _ctx.accumulatedYieldWeight = FixedPointMath.FixedDecimal(0);
    }

    /// @dev Sets the pending governance.
    ///
    /// This function reverts if the new pending governance is the zero address or the caller is not the current
    /// governance. This is to prevent the contract governance being set to the zero address which would deadlock
    /// privileged contract functionality.
    ///
    /// @param _pendingGovernance the new pending governance.
    function setPendingGovernance(address _pendingGovernance) external onlyGov {
        require(_pendingGovernance != ZERO_ADDRESS, "Error: Cannot be the null address");

        pendingGovernance = _pendingGovernance;

        emit PendingGovernanceUpdated(_pendingGovernance);
    }

    /// @dev Accepts the role as governance.
    ///
    /// This function reverts if the caller is not the new pending governance.
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "Error: Sender is not pendingGovernance");

        address _pendingGovernance = pendingGovernance;
        governance = _pendingGovernance;

        emit GovernanceUpdated(_pendingGovernance);
    }

    function setSentinel(address _sentinel) external onlyGov {
        require(_sentinel != ZERO_ADDRESS, "Error: Cannot be the null address");

        sentinel = _sentinel;

        emit SentinelUpdated(_sentinel);
    }

    /// @dev Sets the transmuter.
    ///
    /// This function reverts if the new transmuter is the zero address or the caller is not the current governance.
    ///
    /// @param _transmuter the new transmuter.
    function setTransmuter(address _transmuter) external onlyGov {
        // Check that the transmuter address is not the zero address. Setting the transmuter to the zero address would break
        // transfers to the address because of `safeTransfer` checks.
        require(_transmuter != ZERO_ADDRESS, "Error: Cannot be the null address");

        transmuter = _transmuter;

        emit TransmuterUpdated(_transmuter);
    }

    /// @dev Sets the flushActivator.
    ///
    /// @param _flushActivator the new flushActivator.
    function setFlushActivator(uint256 _flushActivator) external onlyGov {
        flushActivator = _flushActivator;

        emit FlushActivatorUpdated(_flushActivator);
    }

    /*
    /// @dev Sets the price oracle for AUXUSDC. DELETE THIS.
    function setAuxOracleAddress(address oracle) external onlyGov {
        require(oracle != address(0), "GsdLending: Oracle address cannot be 0x0");

        _oracle = PriceOracle.Oracle({oracle: AggregatorV3Interface(oracle)});
    }
    */

    // Sets the AUXUSDC price getter from TraderJoe DEX.
    function setAuxPriceRouterAddress(address router) external onlyGov {
        require(router != address(0), "Error: Cannot be the null address");

        _router = PriceRouter.Router({_router: router, _aux: address(auxToken), _usdc: address(usdcToken)});

        emit AuxPriceRouterUpdated(router);
    }

    // Sets the gsAUX/AUX price getter from TraderJoe DEX.
    function setGsAuxPriceRouterAddress(address router) external onlyGov {
        require(router != address(0), "Error: Cannot be the null address");

        _gsauxrouter = SyntheticRouter.Router({_router: router, _aux: address(auxToken), _gsAux: address(gsAuxToken)});

        emit gsAuxPriceRouterUpdated(router);
    }    

    /// @dev Sets the staking contract.
    ///
    /// This function reverts if the new staking contract is the zero address or the caller is not the current governance.
    ///
    /// @param _staking the new rewards contract.
    function setStaking(address _staking) external onlyGov {
        // Check that the staking address is not the zero address. Setting the staking to the zero address would break
        // transfers to the address because of `safeTransfer` checks.
        require(_staking != ZERO_ADDRESS, "Error: Cannot be the null address");

        staking = _staking;

        emit StakingUpdated(_staking);
    }

    /// @dev Sets the staking fee.
    ///
    /// This function reverts if the caller is not the current governance.
    ///
    /// @param _stakingFee the new staking fee.
    function setStakingFee(uint256 _stakingFee) external onlyGov {
        // Check that the staking fee is within the acceptable range. Setting the staking fee greater than 100% could
        // potentially break internal logic when calculating the staking fee.
        require(_stakingFee.add(harvestFee) <= PERCENT_RESOLUTION, "GsdLending: Fee above maximum");

        stakingFee = _stakingFee;

        emit StakingFeeUpdated(_stakingFee);
    }

    /// @dev Sets the rewards contract.
    ///
    /// This function reverts if the new rewards contract is the zero address or the caller is not the current governance.
    ///
    /// @param _rewards the new rewards contract.
    function setRewards(address _rewards) external onlyGov {
        // Check that the rewards address is not the zero address. Setting the rewards to the zero address would break
        // transfers to the address because of `safeTransfer` checks.
        require(_rewards != ZERO_ADDRESS, "Error: Cannot be the null address");

        rewards = _rewards;

        emit RewardsUpdated(_rewards);
    }

    /// @dev Sets the harvest fee.
    ///
    /// This function reverts if the caller is not the current governance.
    ///
    /// @param _harvestFee the new harvest fee.
    function setHarvestFee(uint256 _harvestFee) external onlyGov {
        // Check that the harvest fee is within the acceptable range. Setting the harvest fee greater than 100% could
        // potentially break internal logic when calculating the harvest fee.
        require(_harvestFee.add(stakingFee) <= PERCENT_RESOLUTION, "GsdLending: Fee above maximum");

        harvestFee = _harvestFee;
        emit HarvestFeeUpdated(_harvestFee);
    }

    /// @dev Sets the collateralization limit.
    ///
    /// This function reverts if the caller is not the current governance or if the collateralization limit is outside
    /// of the accepted bounds.
    ///
    /// @param _limit the new collateralization limit.
    function setCollateralizationLimit(uint256 _limit) external onlyGov {
        require(_limit >= MINIMUM_COLLATERALIZATION_LIMIT, "GsdLending: collateralization limit outside valid range");
        require(_limit <= MAXIMUM_COLLATERALIZATION_LIMIT, "GsdLending: collateralization limit outside valid range");

        _ctx.collateralizationLimit = FixedPointMath.FixedDecimal(_limit);

        emit CollateralizationLimitUpdated(_limit);
    }

    function setMinimumPeg(uint256 peg) external onlyGov {
        pegMinimum = peg;
    }

    /*
    /// @dev Set oracle. Do we need this?
    function setOracleAddress(address Oracle, uint256 peg) external onlyGov {
        _linkGasOracle = Oracle;
        pegMinimum = peg;
    }
    */

    /// @dev Sets if the contract should enter emergency exit mode.
    ///
    /// @param _emergencyExit if the contract should enter emergency exit mode.
    function setEmergencyExit(bool _emergencyExit) external {
        require(msg.sender == governance || msg.sender == sentinel, "Error: Caller not allowed");

        emergencyExit = _emergencyExit;

        emit EmergencyExitUpdated(_emergencyExit);
    }

    /// @dev Gets the collateralization limit.
    ///
    /// The collateralization limit is the minimum ratio of collateral to debt that is allowed by the system.
    ///
    /// @return the collateralization limit.
    function collateralizationLimit() external view returns (FixedPointMath.FixedDecimal memory) {
        return _ctx.collateralizationLimit;
    }

    function accumulatedYieldWeight() external view returns (FixedPointMath.FixedDecimal memory) {
        return _ctx.accumulatedYieldWeight;
    }

    /// @dev Initializes the contract.
    ///
    /// This function checks that the transmuter and rewards have been set and sets up the active vault.
    ///
    /// @param _adapter the vault adapter of the active vault.
    function initialize(IVaultAdapter _adapter) external onlyGov {
        require(!initialized, "GsdLending: already initialized");
        
        require(transmuter != ZERO_ADDRESS, "Error: Cannot be the null address");
        require(staking != ZERO_ADDRESS, "Error: Cannot be the null address");
        require(rewards != ZERO_ADDRESS, "Error: Cannot be the null address");

        _updateActiveVault(_adapter);
        initialized = true;
    }

    /// @dev Migrates the system to a new vault.
    ///
    /// This function reverts if the vault adapter is the zero address, if the token that the vault adapter accepts
    /// is not the token that this contract defines as the parent asset, or if the contract has not yet been initialized.
    ///
    /// @param _adapter the adapter for the vault the system will migrate to.
    function migrate(IVaultAdapter _adapter) external expectInitialized onlyGov {
        _updateActiveVault(_adapter);
    }

    /// @dev Harvests yield from a vault.
    ///
    /// @param _vaultId the identifier of the vault to harvest from.
    ///
    /// @return the amount of funds that were harvested from the vault.
    function harvest(uint256 _vaultId) public expectInitialized returns (uint256, uint256, uint256) {
        Vault.Data storage _vault = _vaults.get(_vaultId);

        uint256 _realisedAux;
        (uint256 _harvestedAmount, uint256 _decreasedValue) = _vault.harvest(address(this));

        if(_harvestedAmount > 0) {
            _realisedAux = _router.swapUsdcForAux(_harvestedAmount);
            require(_realisedAux > 0, "Error: Swap issues");

            uint256 _stakingAmount = _realisedAux.mul(stakingFee).div(PERCENT_RESOLUTION);
            uint256 _feeAmount = _realisedAux.mul(harvestFee).div(PERCENT_RESOLUTION);
            uint256 _distributeAmount = _realisedAux.sub(_feeAmount).sub(_stakingAmount);

            //uint256 _distributeUSDC = _harvestedAmount.sub(_harvestedAmount.mul(stakingFee.add(harvestFee)).div(PERCENT_RESOLUTION));
           
            // Fraction of AUX (18-decimals token) allocated per deposited USDC (6-decimals token).
            FixedPointMath.FixedDecimal memory _weight = FixedPointMath.fromU256(_distributeAmount).div(totalDepositedUsdc);
            _ctx.accumulatedYieldWeight = _ctx.accumulatedYieldWeight.add(_weight);

            if (_feeAmount > 0) {
                auxToken.safeTransfer(rewards, _feeAmount);
            }

            if (_stakingAmount > 0) {
                _distributeToStaking(_stakingAmount);
            }       

            if (_distributeAmount > 0) {
                _distributeToTransmuter(_distributeAmount);
            }
        }

        emit FundsHarvested(_harvestedAmount, _decreasedValue, _realisedAux);
        return (_harvestedAmount, _decreasedValue, _realisedAux);
        /*
        if (_harvestedAmount == 0) return (0,0,0);

        uint256 _realizedAux = _router.swapUsdcForAux(_harvestedAmount);
        if (_realizedAux == 0) return (0,0,0);

        // Realised AUX should be distributed: 90% here, 5% 

        uint256 _stakingAmount = _realizedAux.mul(stakingFee).div(PERCENT_RESOLUTION);
        uint256 _feeAmount = _realizedAux.mul(harvestFee).div(PERCENT_RESOLUTION);
        uint256 _distributeAmount = _realizedAux.sub(_feeAmount).sub(_stakingAmount);


        
        if (_feeAmount > 0) {
            auxToken.safeTransfer(rewards, _feeAmount);
        }

        if (_stakingAmount > 0) {
            _distributeToStaking(_stakingAmount);
        }

        if (_distributeAmount > 0) {
            _distributeAuxYield(_distributeAmount);
        }

        emit FundsHarvested(_harvestedAmount, _decreasedValue, _realizedAux);
        return (_harvestedAmount, _decreasedValue, _realizedAux);
        */
    }
    /*
    /// @dev distribute realized aux earnings
    ///
    /// benefit of GSD protocol
    function _distributeAuxYield(uint256 _distributeAmount) internal {
        uint256 transmuterDeposits = ITransmuter(transmuter).totalSupplyGsAuxtokens();
        uint256 totalDepositedAux = totalDeposited.sub(totalDebt);
        uint256 totalAllocPoint = transmuterDeposits.add(totalDepositedAux);
        if (totalAllocPoint == 0) return;

        uint256 transmuterShares = (_distributeAmount.mul(transmuterDeposits)).div(totalAllocPoint);
        if (totalDepositedAux > 0) {
            FixedPointMath.FixedDecimal memory _weight = FixedPointMath
                .fromU256(_distributeAmount.sub(transmuterShares))
                .div(totalDepositedAux);
            _ctx.accumulatedYieldWeight = _ctx.accumulatedYieldWeight.add(_weight);
        }

        if (transmuterShares > 0) {
            _distributeToTransmuter(transmuterShares);
        }
    }
    */

    /// @dev Claim sender's yield from active vault.
    ///
    /// @return the amount of funds that were harvested from active vault.
    function claim() external expectInitialized returns (uint256) {
        CDP.Data storage _cdp = _cdps[msg.sender];
        _cdp.update(_ctx);
        uint256 _totalCredit = _cdp.totalCredit;
        if (_totalCredit > 0) {
            auxToken.safeTransfer(msg.sender, _totalCredit);
            _cdp.totalCredit = 0;
            return _totalCredit;
        }
         return 0;
    }

    /// @dev Recalls an amount of deposited funds from a vault to this contract.
    ///
    /// @param _vaultId the identifier of the recall funds from.
    ///
    /// @return the amount of funds that were recalled from the vault to this contract and the decreased vault value.
    function recall(uint256 _vaultId, uint256 _amount) external nonReentrant expectInitialized returns (uint256, uint256) {
        return _recallFunds(_vaultId, _amount);
    }

    /// @dev Recalls all the deposited funds from a vault to this contract.
    ///
    /// @param _vaultId the identifier of the recall funds from.
    ///
    /// @return the amount of funds that were recalled from the vault to this contract and the decreased vault value.
    function recallAll(uint256 _vaultId) external nonReentrant expectInitialized returns (uint256, uint256) {
        Vault.Data storage _vault = _vaults.get(_vaultId);
        return _recallFunds(_vaultId, _vault.totalDeposited);
    }

    /// @dev Flushes buffered tokens to the active vault.
    ///
    /// This function reverts if an emergency exit is active. This is in place to prevent the potential loss of
    /// additional funds.
    ///
    /// @return the amount of tokens flushed to the active vault.
    function flush() external nonReentrant expectInitialized returns (uint256) {
        // Prevent flushing to the active vault when an emergency exit is enabled to prevent potential loss of funds if
        // the active vault is poisoned for any reason.
        require(!emergencyExit, "Error: Emergency pause enabled");

        return flushActiveVault();
    }

    /// @dev Internal function to flush buffered tokens to the active vault.
    ///
    /// This function reverts if an emergency exit is active. This is in place to prevent the potential loss of
    /// additional funds.
    ///
    /// @return the amount of tokens flushed to the active vault.
    function flushActiveVault() internal returns (uint256) {
        Vault.Data storage _activeVault = _vaults.last();
        uint256 _depositedAmount = _activeVault.depositAll();

        emit FundsFlushed(_depositedAmount);

        return _depositedAmount;
    }

    /// @dev Deposits collateral into a CDP.
    ///
    /// This function reverts if an emergency exit is active. This is in place to prevent the potential loss of
    /// additional funds.
    ///
    /// @param _amount the amount of collateral to deposit.
    function deposit(uint256 _amount) external nonReentrant expectInitialized {
        require(!emergencyExit, "Error: Emergency pause enabled");

        CDP.Data storage _cdp = _cdps[msg.sender];
        _cdp.update(_ctx);

        usdcToken.safeTransferFrom(msg.sender, address(this), _amount);

        if (_amount >= flushActivator) {
            flushActiveVault();
        }

        totalDepositedUsdc = totalDepositedUsdc.add(_amount);

        uint256 _amountAux = _router.usdcToAuxAmount(totalDepositedUsdc); 
        totalDeposited = _amountAux; // No, unless we update it at every change.

        _cdp.totalDepositedUsdc = _cdp.totalDepositedUsdc.add(_amount);

        uint256 _cdpAmountAux = _router.usdcToAuxAmount(_cdp.totalDepositedUsdc);
        _cdp.totalDeposited = _cdpAmountAux; // No, unless we update it at every change.
        _cdp.lastDeposit = block.timestamp; 

        emit TokensDeposited(msg.sender, _amount);
    }

    /// @dev Attempts to withdraw part of a CDP's collateral.
    ///
    /// This function reverts if a deposit into the CDP was made in the same block. This is to prevent flash loan attacks
    /// on other internal or external systems.
    ///
    /// @param _amount the amount of collateral to withdraw.
    function withdraw(uint256 _amount) external nonReentrant expectInitialized returns (uint256, uint256) {
        CDP.Data storage _cdp = _cdps[msg.sender];
        require(block.number > _cdp.lastDeposit, "Error: Flash loans not allowed");

        _cdp.update(_ctx);

        (uint256 _withdrawnAmount, uint256 _decreasedValue) = _withdrawFundsTo(msg.sender,_amount);

        totalDepositedUsdc = totalDepositedUsdc.sub(_decreasedValue, "Exceeds maximum withdrawable amount");
        totalDeposited = _oracle.usdcToAuxAmount(totalDepositedUsdc);
        _cdp.totalDepositedUsdc = _cdp.totalDepositedUsdc.sub(_decreasedValue, "Exceeds withdrawable amount");
        _cdp.totalDeposited = _oracle.usdcToAuxAmount(_cdp.totalDepositedUsdc);

        _cdp.checkHealth(_ctx, "Action blocked: unhealthy collateralization ratio");

        if (_amount >= flushActivator) {
            flushActiveVault();
        }

        emit TokensWithdrawn(
            msg.sender,
            _amount,
            _withdrawnAmount,
            _decreasedValue
        );

        return (_withdrawnAmount, _decreasedValue);
    }

    /// @dev Repays debt with the native and or synthetic token.
    ///
    /// An approval is required to transfer native tokens to the transmuter.
    /// NoteAcarulo: I took a debt in gsAUX, now i want to repay it by transferring usdc or gsAUX.
    ///              onLinkCheck only if paying with usdc i think.
    function repay(uint256 _usdcAmount, uint256 _gsAuxAmount) external nonReentrant expectInitialized {
        CDP.Data storage _cdp = _cdps[msg.sender];
        _cdp.update(_ctx);

        uint256 _auxAmount = 0;
        if (_usdcAmount > 0) {
            require(_gsauxrouter.gsauxToAux() >= pegMinimum, "Error: gsAUX is not pegged to AUX");

            usdcToken.safeTransferFrom(msg.sender, address(this), _usdcAmount);
            _auxAmount = SwapRouter.swapUsdcForAux(_usdcAmount);
            //_distributeAuxYield(_auxAmount);
        }

        if (_gsAuxAmount > 0) {
            gsAuxToken.burnFrom(msg.sender, _gsAuxAmount);
            //lower debt cause burn
            gsAuxToken.lowerHasMinted(_gsAuxAmount);
        }

        uint256 _totalAmount = _auxAmount.add(_gsAuxAmount);
        if (_totalAmount > _cdp.totalDebt) {
            uint256 _diff = _totalAmount.sub(_cdp.totalDebt);
            auxToken.transfer(msg.sender, _diff);
            totalDebt = totalDebt.sub(_cdp.totalDebt, "Exceeds minimum total debt in Gold");
            _cdp.totalDebt = 0;
        } else {
            _cdp.totalDebt = _cdp.totalDebt.sub(_totalAmount, "Exceeds withdrawable amount Gold");
            totalDebt = totalDebt.sub(_totalAmount, "Exceeds withdrawable amount Gold");
        }

        emit TokensRepaid(msg.sender, _usdcAmount, _gsAuxAmount);
    }

    /// @dev Attempts to liquidate part of a CDP's collateral to pay back its debt.
    ///
    /// @param _amount the amount of collateral to attempt to liquidate.
    /// NoteAcarulo: Checked.
    function liquidate(uint256 _amount) external nonReentrant expectInitialized returns (uint256, uint256) {
        require(_gsauxrouter.gsauxToAux() >= pegMinimum, "Error: gsAUX is not pegged to AUX"); // May remove this.

        CDP.Data storage _cdp = _cdps[msg.sender];
        _cdp.update(_ctx);

        // don't attempt to liquidate more than is possible
        uint256 _liquidateAMount = _amount;
        if (_liquidateAMount > _cdp.totalDepositedUsdc) {
            _liquidateAMount = _cdp.totalDepositedUsdc;
        }

        (uint256 _withdrawnAmount, uint256 _decreasedValue) = _withdrawFundsTo(address(this), _liquidateAMount);
        uint256 _withdrawnGoldAmount = SwapRouter.swapUsdcForAux(_withdrawnAmount);
        //_distributeAuxYield(_withdrawnGoldAmount);

        _cdp.totalDepositedUsdc = _cdp.totalDepositedUsdc.sub(_decreasedValue, "Exceeds withdrawable amount");
        _cdp.totalDeposited = _oracle.usdcToAuxAmount(_cdp.totalDepositedUsdc);
        totalDepositedUsdc = totalDepositedUsdc.sub(_decreasedValue, "Exceeds maximum withdrawable amount");
        totalDeposited = _oracle.usdcToAuxAmount(totalDepositedUsdc);

        uint256 diff = _withdrawnGoldAmount > _cdp.totalDebt ? _cdp.totalDebt : 0;
        _cdp.totalDebt = _cdp.totalDebt.sub(diff, "Exceeds withdrawable amount Gold");
        totalDebt = totalDebt.sub(diff, "Exceeds max withdrawable amount Gold");

        emit TokensLiquidated(
            msg.sender,
            _liquidateAMount,
            _withdrawnAmount,
            _decreasedValue
        );

        return (_withdrawnAmount, _decreasedValue);
    }

    /// @dev Mints synthetic tokens by either claiming credit or increasing the debt.
    ///
    /// Claiming credit will take priority over increasing the debt.
    ///
    /// This function reverts if the debt is increased and the CDP health check fails.
    /// NoteAcarulo: if gsAUX value is much lower than AUX, should I allow minting? Definitely not.
    /// @param _amount the amount of gsAux tokens to borrow.
    function mint(uint256 _amount) external nonReentrant expectInitialized {
        CDP.Data storage _cdp = _cdps[msg.sender];
        _cdp.update(_ctx);

        require(_gsauxrouter.gsauxToAux() >= pegMinimum, "Error: gsAUX is not pegged to AUX");

        uint256 _totalCredit = _cdp.totalCredit;
        if (_totalCredit < _amount) {
            uint256 _remainingAmount = _amount.sub(_totalCredit);
            _cdp.totalDebt = _cdp.totalDebt.add(_remainingAmount);
            _cdp.totalCredit = 0;
            totalDebt = totalDebt.add(_remainingAmount);

            _cdp.checkHealth(_ctx, "GsdLending: Loan-to-value ratio breached");
        } else {
            _cdp.totalCredit = _totalCredit.sub(_amount);
        }

        gsAuxToken.mint(msg.sender, _amount);

        uint256 _amountUsdc = _oracle.auxToUsdcAmount(_amount);
        if (_amountUsdc >= flushActivator) {
            flushActiveVault();
        }
    }

    /// @dev Gets the number of vaults in the vault list.
    ///
    /// @return the vault count.
    function vaultCount() external view returns (uint256) {
        return _vaults.length();
    }

    /// @dev Get the adapter of a vault.
    ///
    /// @param _vaultId the identifier of the vault.
    ///
    /// @return the vault adapter.
    function getVaultAdapter(uint256 _vaultId) external view returns (IVaultAdapter) {
        Vault.Data storage _vault = _vaults.get(_vaultId);
        return _vault.adapter;
    }

    /// @dev Get the total amount of the parent asset that has been deposited into a vault.
    ///
    /// @param _vaultId the identifier of the vault.
    ///
    /// @return the total amount of deposited tokens.
    function getVaultTotalDeposited(uint256 _vaultId)
        external
        view
        returns (uint256)
    {
        Vault.Data storage _vault = _vaults.get(_vaultId);
        return _vault.totalDeposited;
    }

    function getUserCDPData(address account) external view returns (CDP.Data memory) {
        CDP.Data storage _cdp = _cdps[account];
        return _cdp;
    }

    /// @dev Get the total amount of collateral deposited into a CDP in aux terms.
    ///
    /// @param _account the user account of the CDP to query.
    ///
    /// @return the deposited amount of tokens.
    function getCdpTotalDeposited(address _account)
        external
        view
        returns (uint256)
    {
        CDP.Data storage _cdp = _cdps[_account];
        return _cdp.totalDeposited;
    }

    /// @dev Get the total amount of collateral deposited into a CDP.
    ///
    /// @param _account the user account of the CDP to query.
    ///
    /// @return the deposited amount of tokens.
    function getCdpTotalDepositedUsdc(address _account)
        external
        view
        returns (uint256)
    {
        CDP.Data storage _cdp = _cdps[_account];
        return _cdp.totalDepositedUsdc;
    }

    /// @dev Get the total amount of gsdAux tokens borrowed from a CDP.
    ///
    /// @param _account the user account of the CDP to query.
    ///
    /// @return the borrowed amount of tokens.
    /// NoteAugusto: Checked.
    function getCdpTotalDebt(address _account) external view returns (uint256) {
        CDP.Data storage _cdp = _cdps[_account];
        return _cdp.getUpdatedTotalDebt(_ctx);
    }

    /// @dev Get the total amount of credit that a CDP has.
    ///
    /// @param _account the user account of the CDP to query.
    ///
    /// @return the amount of credit.
    function getCdpTotalCredit(address _account)
        external
        view
        returns (uint256)
    {
        CDP.Data storage _cdp = _cdps[_account];
        return _cdp.getUpdatedTotalCredit(_ctx);
    }

    /// @dev Get the total amount of aux that a CDP has.
    ///
    /// @param _account the user account of the CDP to query.
    ///
    /// @return the amount of earnings.
    function getCdpPendingRewards(address _account)
        external
        view
        returns (uint256)
    {
        CDP.Data storage _cdp = _cdps[_account];
        return _cdp.totalCredit;
    }

    /// @dev Gets the last recorded block of when a user made a deposit into their CDP.
    ///
    /// @param _account the user account of the CDP to query.
    ///
    /// @return the block number of the last deposit.
    function getCdpLastDeposit(address _account) external view returns (uint256) {
        CDP.Data storage _cdp = _cdps[_account];
        return _cdp.lastDeposit;
    } 

    /// @dev sends tokens to the transmuter
    ///
    /// benefit of great nation of transmuter
    function _distributeToTransmuter(uint256 amount) internal {
        auxToken.approve(transmuter, amount);
        ITransmuter(transmuter).distribute(address(this), amount);
        // lower debt cause of 'burn'
        gsAuxToken.lowerHasMinted(amount);
    }

    /// @dev sends tokens to the staking contract
    function _distributeToStaking(uint256 amount) internal {
        auxToken.approve(staking, amount);
        IGsdStaking(staking).deposit(amount);
    }
    /*
    /// @dev Checks that parent token is on peg.
    ///
    /// This is used over a modifier limit of pegged interactions.
    modifier onLinkCheck() {
        if (pegMinimum > 0) {
            uint256 oracleAnswer = uint256(
                IChainlink(_linkGasOracle).latestAnswer()
            );
            require(oracleAnswer > pegMinimum, "off peg limitation");
        }
        _;
    }
    
    /// @dev Checks that caller is not a eoa.
    ///
    /// This is used to prevent contracts from interacting.
    modifier noContractAllowed() {
        require(
            !address(msg.sender).isContract() && msg.sender == tx.origin,
            "Sorry we do not accept contract!"
        );
        _;
    }
    */

    /// @dev Checks that the contract is in an initialized state.
    ///
    /// This is used over a modifier to reduce the size of the contract
    modifier expectInitialized() {
        require(initialized, "GsdLending: not initialized");
        _;
    }

    /// @dev Checks that the current message sender or caller is a specific address.
    ///
    /// @param _expectedCaller the expected caller.
    function _expectCaller(address _expectedCaller) internal view {
        require(msg.sender == _expectedCaller, "");
    }

    /// @dev Checks that the current message sender or caller is the governance address.
    ///
    ///
    modifier onlyGov() {
        require(msg.sender == governance, "GsdLending: only governance");
        _;
    }

    /// @dev Set sushiswap router.
    ///
    /// This function reverts if the router is the zero address, or if this contract has not yet been initialized.
    ///
    /// @param _router sushi router for swaping usdc to aux.
    function setSushiswapRouter(address _router) public onlyGov {
        require(
            _router != ZERO_ADDRESS,
            "GsdLending: sushi router address cannot be 0x0."
        );

        SwapRouter = SwapRouterLib.State({sushiswapRouter: address(_router), auxToken: address(auxToken), usdcToken: address(usdcToken)});
        emit RouterIsSet(_router);
    }

    /// @dev Updates the active vault.
    ///
    /// This function reverts if the vault adapter is the zero address, if the token that the vault adapter accepts
    /// is not the token that this contract defines as the parent asset, or if the contract has not yet been initialized.
    ///
    /// @param _adapter the adapter for the new active vault.
    function _updateActiveVault(IVaultAdapter _adapter) internal {
        require(_adapter != IVaultAdapter(ZERO_ADDRESS), "Error: Cannot be the null address");
        require(_adapter.token() == usdcToken, "GsdLending: token mismatch");

        _vaults.push(Vault.Data({adapter: _adapter, totalDeposited: 0}));

        emit ActiveVaultUpdated(_adapter);
    }

    /// @dev Recalls an amount of funds from a vault to this contract.
    ///
    /// @param _vaultId the identifier of the recall funds from.
    /// @param _amount  the amount of funds to recall from the vault.
    ///
    /// @return the amount of funds that were recalled from the vault to this contract and the decreased vault value.
    function _recallFunds(uint256 _vaultId, uint256 _amount)
        internal
        returns (uint256, uint256)
    {
        require(emergencyExit || msg.sender == governance || _vaultId != _vaults.lastIndex(),
            "GsdLending: user does not have permission to recall funds from active vault"
        );

        Vault.Data storage _vault = _vaults.get(_vaultId);
        (uint256 _withdrawnAmount, uint256 _decreasedValue) = _vault.withdraw(
            address(this),
            _amount
        );

        emit FundsRecalled(_vaultId, _withdrawnAmount, _decreasedValue);

        return (_withdrawnAmount, _decreasedValue);
    }

    /// @dev Attempts to withdraw funds from the active vault to the recipient.
    ///
    /// Funds will be first withdrawn from this contracts balance and then from the active vault. This function
    /// is different from `recallFunds` in that it reduces the total amount of deposited tokens by the decreased
    /// value of the vault.
    ///
    /// @param _recipient the account to withdraw the funds to.
    /// @param _amount    the amount of funds to withdraw.
    function _withdrawFundsTo(address _recipient, uint256 _amount)
        internal
        returns (uint256, uint256)
    {
        // Pull the funds from the buffer.
        uint256 _bufferedAmount = Math.min(
            _amount,
            usdcToken.balanceOf(address(this))
        );

        if (_recipient != address(this) && _bufferedAmount > 0) {
            usdcToken.safeTransfer(_recipient, _bufferedAmount);
        }

        uint256 _totalWithdrawn = _bufferedAmount;
        uint256 _totalDecreasedValue = _bufferedAmount;

        uint256 _remainingAmount = _amount.sub(_bufferedAmount);

        // Pull the remaining funds from the active vault.
        if (_remainingAmount > 0) {
            Vault.Data storage _activeVault = _vaults.last();
            (uint256 _withdrawAmount, uint256 _decreasedValue) = _activeVault
                .withdraw(_recipient, _remainingAmount);

            _totalWithdrawn = _totalWithdrawn.add(_withdrawAmount);
            _totalDecreasedValue = _totalDecreasedValue.add(_decreasedValue);
        }

        return (_totalWithdrawn, _totalDecreasedValue);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {FixedPointMath} from "../FixedPointMath.sol";
import {IDetailedERC20} from "../../interfaces/IDetailedERC20.sol";
import "hardhat/console.sol";

/// @title CDP
///
/// @dev A library which provides the CDP data struct and associated functions.
library CDP {
  using CDP for Data;
  using FixedPointMath for FixedPointMath.FixedDecimal;
  using SafeERC20 for IDetailedERC20;
  using SafeMath for uint256;

  struct Context {
    FixedPointMath.FixedDecimal collateralizationLimit;
    FixedPointMath.FixedDecimal accumulatedYieldWeight;
  }

  struct Data {
    uint256 totalDeposited;           // In AUX, 18-decimals units.
    uint256 totalDepositedUsdc;       // In USDC, 6-decimals units.
    uint256 totalDebt;                // In gsAUX, 18-decimals units.
    uint256 totalCredit;              // In AUX, 6-decimals units.
    uint256 lastDeposit;              // In timestamp, not block number.
    FixedPointMath.FixedDecimal lastAccumulatedYieldWeight;
  }

  function update(Data storage _self, Context storage _ctx) internal {
    uint256 _earnedYield = _self.getEarnedYield(_ctx);

    if (_earnedYield > _self.totalDebt) {
      uint256 _currentTotalDebt = _self.totalDebt;
      _self.totalDebt = 0;
      _self.totalCredit = _earnedYield.sub(_currentTotalDebt);
    } else {
      _self.totalDebt = _self.totalDebt.sub(_earnedYield);
    }

    _self.lastAccumulatedYieldWeight = _ctx.accumulatedYieldWeight;
  }

  /// @dev Assures that the CDP is healthy.
  ///
  /// This function will revert if the CDP is unhealthy.
  function checkHealth(Data storage _self, Context storage _ctx, string memory _msg) internal view {
    require(_self.isHealthy(_ctx), _msg);
  }

  /// @dev Gets if the CDP is considered healthy.
  ///
  /// A CDP is healthy if its collateralization ratio is greater than the global collateralization limit.
  ///
  /// @return if the CDP is healthy.
  function isHealthy(Data storage _self, Context storage _ctx) internal view returns (bool) {
    return _ctx.collateralizationLimit.cmp(_self.getCollateralizationRatio(_ctx)) <= 0;
  }

  function getUpdatedTotalDebt(Data storage _self, Context storage _ctx) internal view returns (uint256) {
    uint256 _unclaimedYield = _self.getEarnedYield(_ctx);
    if (_unclaimedYield == 0) {
      return _self.totalDebt;
    }

    uint256 _currentTotalDebt = _self.totalDebt;
    if (_unclaimedYield >= _currentTotalDebt) {
      return 0;
    }

    return _currentTotalDebt - _unclaimedYield;
  }

  function getUpdatedTotalCredit(Data storage _self, Context storage _ctx) internal view returns (uint256) {
    uint256 _unclaimedYield = _self.getEarnedYield(_ctx);
    if (_unclaimedYield == 0) {
      return _self.totalCredit;
    }

    uint256 _currentTotalDebt = _self.totalDebt;
    if (_unclaimedYield <= _currentTotalDebt) {
      return 0;
    }

    return _self.totalCredit + (_unclaimedYield - _currentTotalDebt);
  }

  /// @dev Gets the amount of yield that a CDP has earned since the last time it was updated.
  ///
  /// @param _self the CDP to query.
  /// @param _ctx  the CDP context.
  ///
  /// @return the amount of earned yield.
  function getEarnedYield(Data storage _self, Context storage _ctx) internal view returns (uint256) {
    FixedPointMath.FixedDecimal memory _currentAccumulatedYieldWeight = _ctx.accumulatedYieldWeight;
    FixedPointMath.FixedDecimal memory _lastAccumulatedYieldWeight = _self.lastAccumulatedYieldWeight;

    if (_currentAccumulatedYieldWeight.cmp(_lastAccumulatedYieldWeight) == 0) {
      return 0;
    }

    return _currentAccumulatedYieldWeight.sub(_lastAccumulatedYieldWeight).mul(_self.totalDeposited).decode();
  }

  /// @dev Gets a CDPs collateralization ratio.
  ///
  /// The collateralization ratio is defined as the ratio of collateral to debt. If the CDP has zero debt then this
  /// will return the maximum value of a fixed point integer.
  ///
  /// This function will use the updated total debt so an update before calling this function is not required.
  ///
  /// @param _self the CDP to query.
  ///
  /// @return a fixed point integer representing the collateralization ratio.
  function getCollateralizationRatio(Data storage _self, Context storage _ctx) internal view returns (FixedPointMath.FixedDecimal memory) {
    uint256 _totalDebt = _self.getUpdatedTotalDebt(_ctx);

    if (_totalDebt == 0) {
      return FixedPointMath.maximumValue();
    }
    return FixedPointMath.fromU256(_self.totalDeposited).div(_totalDebt);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface ITransmuter  {
  function distribute (address origin, uint256 amount) external;
  function autoTransmuteAndClaim (address sender) external returns (uint256);
  function totalSupplyGsAuxtokens () external returns (uint256);
  function userInfo (address sender) external returns (
            uint256 depositedGsAux,
            uint256 pendingdivs,
            uint256 inbucket,
            uint256 realised
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IChainlink {
  function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {AggregatorV3Interface} from "../../interfaces/AggregatorV3Interface.sol";

library PriceOracle {
    using PriceOracle for Oracle;
    using SafeMath for uint256;

    struct Oracle {
        AggregatorV3Interface oracle;
    }

    uint256 public constant SCALAR_ORACLE = 1e8; // This should be checked when we have the oracle.
    uint256 public constant GOLD_TOKEN_USDC = 1e0; // The gold token decimal and usdc decimal differences

    function auxToUsdcAmount(Oracle storage _self, uint256 _amount) internal view returns(uint256) {
        uint256 _price = getGoldTokenPrice(_self);
        return _amount.mul(_price).div(SCALAR_ORACLE).div(GOLD_TOKEN_USDC);
    }

    function usdcToAuxAmount(Oracle storage _self, uint256 _amount) internal view returns(uint256) {
        uint256 _price = getGoldTokenPrice(_self);
        return _amount.mul(SCALAR_ORACLE).mul(GOLD_TOKEN_USDC).div(_price);
    }

    function getGoldTokenPrice(Oracle storage _self) internal view returns (uint256) {
        (, int256 price, , , ) = _self.oracle.latestRoundData();
        require(price >= 0, "Error: Invalid price feed");
        return uint256(price);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import "../../interfaces/IUniswapV2Router02.sol";
import "../../interfaces/IDetailedERC20.sol";

library SyntheticRouter {

    using SafeMath for uint256;

    struct Router {
        address _router;
        address _aux;
        address _gsAux;
    }

    uint256 public constant UNIT = 1e18;

    function auxToGsaux(Router storage _self) internal view returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = _self._aux;
        path[1] = _self._gsAux;

        uint256[] memory amounts = IUniswapV2Router02(_self._router).getAmountsOut(UNIT, path);
        
        return amounts[1];
    }

    function gsauxToAux(Router storage _self) internal view returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = _self._gsAux;
        path[1] = _self._aux;

        uint256[] memory amounts = IUniswapV2Router02(_self._router).getAmountsOut(UNIT, path);
        
        return amounts[1];
    }



}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {ISushiSwapRouter} from "../../interfaces/ISushiSwapRouter.sol";

library SwapRouterLib {
    using SwapRouterLib for State;
    using SafeMath for uint256;

    struct State {
        address sushiswapRouter;
        address usdcToken;
        address auxToken;
    }

    /// @dev takes usdc and swaps for aux tokens
    function swap(State storage _self, uint256 usdcAmount) internal {
        // generate the sushiswap pair path of usdc -> aux
        address[] memory path = new address[](2);
        path[0] = _self.usdcToken;
        path[1] = _self.auxToken;

        IERC20(_self.usdcToken).approve(_self.sushiswapRouter, usdcAmount);

        // call sushiswap router to perform swap
        ISushiSwapRouter(_self.sushiswapRouter).swapExactTokensForTokens(
            usdcAmount,
            0, // accept any amount of AUX
            path,
            address(this),
            block.timestamp
        );
    }

    function swapUsdcForAux(State storage _self, uint256 usdcAmount) internal returns(uint256 realizedAux) {
        // check contract aux balance before swap
        uint256 balBefore = IERC20(_self.auxToken).balanceOf(address(this));

        // perform swap here
        _self.swap(usdcAmount);

        // check contract aux balance after swap
        uint256 balAfter = IERC20(_self.auxToken).balanceOf(address(this));

        realizedAux = balAfter.sub(balBefore);
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
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
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface ISushiSwapRouter {
    function factory() external pure returns (address);

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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IDetailedERC20} from "../interfaces/IDetailedERC20.sol";

/// @title GsAuxToken
///
/// @dev This is the contract for the Gsdite-aux utillity token usd.
///
/// Initially, the contract deployer is given both the admin and minter role. This allows them to pre-mine tokens,
/// transfer admin to a timelock contract, and lastly, grant the staking pools the minter role. After this is done,
/// the deployer must revoke their admin role and minter role.
contract GsAuxTokenMock is AccessControl, ERC20("Gsd AUX", "gsdAux") {
  using SafeERC20 for ERC20;

  /// @dev The identifier of the role which maintains other roles.
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

  /// @dev The identifier of the role which allows accounts to mint tokens.
  bytes32 public constant SENTINEL_ROLE = keccak256("SENTINEL");
  
  /// @dev addresses whitelisted for minting new tokens
  mapping (address => bool) public whiteList;
  
  /// @dev addresses blacklisted for minting new tokens
  mapping (address => bool) public blacklist;

  /// @dev addresses paused for minting new tokens
  mapping (address => bool) public paused;

  /// @dev ceiling per address for minting new tokens
  mapping (address => uint256) public ceiling;

  /// @dev already minted amount per address to track the ceiling
  mapping (address => uint256) public hasMinted;

  event Paused(address gsditeAddress, bool isPaused);
  
  constructor() public {
    _setupRole(ADMIN_ROLE, msg.sender);
    _setupRole(SENTINEL_ROLE, msg.sender);
    _setRoleAdmin(SENTINEL_ROLE,ADMIN_ROLE);
    _setRoleAdmin(ADMIN_ROLE,ADMIN_ROLE);
  }

  function decimals() public view virtual override returns (uint8) {
      return 6;
  }

  /// @dev A modifier which checks if whitelisted for minting.
  modifier onlyWhitelisted() {
    require(whiteList[msg.sender], "GsAux: Gsdite is not whitelisted");
    _;
  }

  /// @dev Mints tokens to a recipient.
  ///
  /// This function reverts if the caller does not have the minter role.
  ///
  /// @param _recipient the account to mint tokens to.
  /// @param _amount    the amount of tokens to mint.
  function mint(address _recipient, uint256 _amount) external {
    require(!blacklist[msg.sender], "GsAux: Gsdite is blacklisted.");
    require(!paused[msg.sender], "GsAux: user is currently paused.");
    hasMinted[msg.sender] = hasMinted[msg.sender].add(_amount);
    _mint(_recipient, _amount);
  }
  /// This function reverts if the caller does not have the admin role.
  ///
  /// @param _toWhitelist the account to mint tokens to.
  /// @param _state the whitelist state.

  function setWhitelist(address _toWhitelist, bool _state) external onlyAdmin {
    whiteList[_toWhitelist] = _state;
  }
  /// This function reverts if the caller does not have the admin role.
  ///
  /// @param _newSentinel the account to set as sentinel.

  function setSentinel(address _newSentinel) external onlyAdmin {
    _setupRole(SENTINEL_ROLE, _newSentinel);
  }
  /// This function reverts if the caller does not have the admin role.
  ///
  /// @param _toBlacklist the account to mint tokens to.
  function setBlacklist(address _toBlacklist) external {
    blacklist[_toBlacklist] = true;
  }
  /// This function reverts if the caller does not have the admin role.
  function pauseGsdite(address _toPause, bool _state) external {
    paused[_toPause] = _state;
    Paused(_toPause, _state);
  }
  /// This function reverts if the caller does not have the admin role.
  ///
  /// @param _toSetCeiling the account set the ceiling off.
  /// @param _ceiling the max amount of tokens the account is allowed to mint.
  function setCeiling(address _toSetCeiling, uint256 _ceiling) external onlyAdmin {
    ceiling[_toSetCeiling] = _ceiling;
  }
   /// @dev A modifier which checks that the caller has the admin role.
  modifier onlyAdmin() {
    require(hasRole(ADMIN_ROLE, msg.sender), "only admin");
    _;
  }
  /// @dev A modifier which checks that the caller has the sentinel role.
  modifier onlySentinel() {
    require(hasRole(SENTINEL_ROLE, msg.sender), "only sentinel");
    _;
  }
  /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
    /**
     * @dev lowers hasminted from the caller's allocation
     *
     */
    function lowerHasMinted( uint256 amount) public {
        if (hasMinted[msg.sender] >= amount) {
          hasMinted[msg.sender] = hasMinted[msg.sender].sub(amount);
        } else {
          hasMinted[msg.sender] = 0;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

//SPDX-License-Identifier: MIT.
pragma solidity = 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract RewardsDistributor is Ownable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    uint256 public constant PERCENTAGE_FACTOR = 10000;
    
    address public immutable token;

    address[] public accounts;
    mapping(address => uint256) public accountShares;

    event AccountsSet(address[] accounts, uint256[] shares);
    event PaymentsDistributed(address[] accounts, uint256[] amounts);

    constructor(address _token, address[] memory _accounts, uint256[] memory _shares) public {
        require(_token != address(0), "Error: Null address");

        token = _token;
        _setAccounts(_accounts, _shares);
    }

    modifier onlyAuthorized() {
        require(msg.sender == owner() || accountShares[msg.sender] > 0, "Error: Caller not authorized");
        _;
    }

    function resetAccounts(address[] memory _accounts, uint256[] memory _shares) external onlyOwner {
        _deleteAccounts();
        _setAccounts(_accounts, _shares);
    }

    function _deleteAccounts() internal {
        for (uint256 i = 0; i < accounts.length; i++) {
            accountShares[accounts[i]] = 0;
        }

        delete accounts;
    }

    function _setAccounts(address[] memory _accounts, uint256[] memory _shares) internal {
        require(_accounts.length == _shares.length, "Error: Array lengths do not match");

        uint256 total;
        for (uint256 i = 0; i < _shares.length; i++) {
            require(_accounts[i] != address(0), "Error: account is the null address");
            total += _shares[i];
        }

        require(total == PERCENTAGE_FACTOR, "Error: shares do not add up to 100%");

        accounts = _accounts;

        for (uint256 i = 0; i < _accounts.length; i++) {
            accountShares[_accounts[i]] = _shares[i];
        }

        emit AccountsSet(_accounts, _shares);
    }

    function withdrawAUX() external onlyAuthorized {
        uint256 currentAUXBalance = IERC20(token).balanceOf(address(this));
        require(currentAUXBalance != 0, "Error: Null AUX balance");

        uint256[] memory transferredBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; i++) {
            uint256 balance = currentAUXBalance.mul(accountShares[accounts[i]]).div(PERCENTAGE_FACTOR);
            transferredBalances[i] = balance;

            IERC20(token).safeTransfer(accounts[i], balance);
        }

        emit PaymentsDistributed(accounts, transferredBalances);
    }

    function getAccounts() external view returns(address[] memory) {
        return accounts;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interfaces/IYearnController.sol";
import "../interfaces/IYearnVault.sol";

contract YearnVaultMock is  ERC20 {
  using SafeERC20 for IDetailedERC20;
  using SafeMath for uint256;

  uint256 public min = 9500;
  uint256 public constant max = 10000;

  IYearnController public controller;
  IDetailedERC20 public token;

  constructor(IDetailedERC20 _token, IYearnController _controller) public ERC20("yEarn Mock", "yMOCK") {
    token = _token;
    controller = _controller;
  }

  function vdecimals() external view returns (uint8) {
    return decimals();
  }

  function balance() public view  returns (uint256) {
    return token.balanceOf(address(this)).add(controller.balanceOf(address(token)));
  }

  function available() public view  returns (uint256) {
    return token.balanceOf(address(this)).mul(min).div(max);
  }

  function earn() external  {
    uint _bal = available();
    token.safeTransfer(address(controller), _bal);
    controller.earn(address(token), _bal);
  }

  function deposit(uint256 _amount) external returns (uint){
    uint _pool = balance();
    uint _before = token.balanceOf(address(this));
    token.safeTransferFrom(msg.sender, address(this), _amount);
    uint _after = token.balanceOf(address(this));
    _amount = _after.sub(_before); // Additional check for deflationary tokens
    uint _shares = 0;
    if (totalSupply() == 0) {
      _shares = _amount;
    } else {
      _shares = (_amount.mul(totalSupply())).div(_pool);
    }
    _mint(msg.sender, _shares);
  }

  function withdraw(uint _shares, address _recipient) external returns (uint) {
    uint _r = (balance().mul(_shares)).div(totalSupply());
    _burn(msg.sender, _shares);

    // Check balance
    uint _b = token.balanceOf(address(this));
    if (_b < _r) {
      uint _withdraw = _r.sub(_b);
      controller.withdraw(address(token), _withdraw);
      uint _after = token.balanceOf(address(this));
      uint _diff = _after.sub(_b);
      if (_diff < _withdraw) {
        _r = _b.add(_diff);
      }
    }

    token.safeTransfer(_recipient, _r);
  }

  function pricePerShare() external view returns (uint256) {
    return balance().mul(1e18).div(totalSupply());
  }// changed to v2

  /// @dev This is not part of the vault contract and is meant for quick debugging contracts to have control over
  /// completely clearing the vault buffer to test certain behaviors better.
  function clear() external {
    token.safeTransfer(address(controller), token.balanceOf(address(this)));
    controller.earn(address(token), token.balanceOf(address(this)));
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

interface IYearnController {
  function balanceOf(address _token) external view returns (uint256);
  function earn(address _token, uint256 _amount) external;
  function withdraw(address _token, uint256 _withdrawAmount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IDetailedERC20} from "./IDetailedERC20.sol";

interface IYearnVault  {
    function balanceOf(address user)  external view returns (uint);
    function pricePerShare()  external view returns (uint);
    function deposit(uint amount)  external returns (uint);
    function withdraw(uint shares, address recipient)  external returns (uint); 
    function token() external view returns (IDetailedERC20);
    function totalAssets()  external view returns (uint);
    function decimals() external  view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IYearnController.sol";

contract YearnControllerMock is IYearnController {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address constant public blackhole = 0x000000000000000000000000000000000000dEaD;

  uint256 public withdrawalFee = 50;
  uint256 constant public withdrawalMax = 10000;

  function setWithdrawalFee(uint256 _withdrawalFee) external {
    withdrawalFee = _withdrawalFee;
  }

  function balanceOf(address _token) external view override returns (uint256) {
    return IERC20(_token).balanceOf(address(this));
  }

  function earn(address _token, uint256 _amount) external override { }

  function withdraw(address _token, uint256 _amount) external override {
    uint _balance = IERC20(_token).balanceOf(address(this));
    // uint _fee = _amount.mul(withdrawalFee).div(withdrawalMax);

    // IERC20(_token).safeTransfer(blackhole, _fee);
    IERC20(_token).safeTransfer(msg.sender, _amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IMintableERC20} from "../interfaces/IMintableERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SushiSwapMock {
    using SafeMath for uint256;
    IMintableERC20 public aux;

    constructor(address _aux) public {
        aux = IMintableERC20(_aux);
    }

    function factory() external pure returns (address) {
        return address(0);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256, uint256) {
        return (0, 0);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256, uint256) {
        uint256 price = 1900;
        uint256 amountOut = amountIn.div(price);
        aux.mint(to, amountOut);
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        return (0, 0);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity = 0.6.12;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IDetailedERC20} from "../interfaces/IDetailedERC20.sol";
import {IMintableERC20} from "../interfaces/IMintableERC20.sol";

contract AdapterMock {

    using SafeERC20 for IDetailedERC20;
    using SafeMath for uint256;

    IDetailedERC20 public _token;

    mapping(address => uint256) public depositors;

    uint256 public constant checkpoint = 600;
    uint256 public lastWithdrawal;

    constructor(IDetailedERC20 token_) public {
        _token = token_;
        lastWithdrawal = block.timestamp;
    }

    function token() external view returns (IDetailedERC20) {
        return _token;
    }

    function totalValue() external view returns (uint256) {
        if(lastWithdrawal + checkpoint <= block.timestamp && _token.balanceOf(address(this)) > 0) {
            return _token.balanceOf(address(this)) + 1 * 10 ** 6; // Only valid for 6-decimals tokens.

        } else {
            return _token.balanceOf(address(this));
        }
    }

    function deposit(uint256 _amount) external {
        IDetailedERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        depositors[msg.sender] = depositors[msg.sender].add(_amount);
    }

    function withdraw(address _recipient, uint256 _amount, bool _isCapital) external {
        uint256 currentBalance = depositors[msg.sender];
        //require(currentBalance == _token.balanceOf(address(this)));

        if(lastWithdrawal + checkpoint <= block.timestamp && _token.balanceOf(address(this)) > 0) {
            IMintableERC20(address(_token)).mint(address(this), 10 ** 6);
            depositors[msg.sender] = currentBalance.add(10 ** 6);
            lastWithdrawal = block.timestamp;
        }

        depositors[msg.sender] = currentBalance.sub(_amount);

        IDetailedERC20(_token).safeTransfer(_recipient, _amount);

        // If capital is not withdrawn, adapter balance should equal at least initial balance.
        if(!_isCapital) {
            currentBalance >= depositors[msg.sender].sub(_amount);
        }        
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {FixedPointMath} from "../FixedPointMath.sol";
import {IDetailedERC20} from "../../interfaces/IDetailedERC20.sol";
import {Pool} from "./Pool.sol";

import "hardhat/console.sol";

/// @title Stake
///
/// @dev A library which provides the Stake data struct and associated functions.
library Stake {
  using FixedPointMath for FixedPointMath.FixedDecimal;
  using Pool for Pool.Data;
  using SafeMath for uint256;
  using Stake for Stake.Data;

  struct Data {
    uint256 totalDeposited;
    uint256 totalUnclaimed;
    FixedPointMath.FixedDecimal lastAccumulatedWeight;
  }

  function update(Data storage _self, Pool.Data storage _pool, Pool.Context storage _ctx) internal {
    _self.totalUnclaimed = _self.getUpdatedTotalUnclaimed(_pool, _ctx);
    _self.lastAccumulatedWeight = _pool.getUpdatedAccumulatedRewardWeight(_ctx);
  }

  function getUpdatedTotalUnclaimed(Data storage _self, Pool.Data storage _pool, Pool.Context storage _ctx)
    internal view
    returns (uint256)
  {
    FixedPointMath.FixedDecimal memory _currentAccumulatedWeight = _pool.getUpdatedAccumulatedRewardWeight(_ctx);
    FixedPointMath.FixedDecimal memory _lastAccumulatedWeight = _self.lastAccumulatedWeight;

    if (_currentAccumulatedWeight.cmp(_lastAccumulatedWeight) == 0) {
      return _self.totalUnclaimed;
    }

    uint256 _distributedAmount = _currentAccumulatedWeight
      .sub(_lastAccumulatedWeight)
      .mul(_self.totalDeposited)
      .decode();

    return _self.totalUnclaimed.add(_distributedAmount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {FixedPointMath} from "../FixedPointMath.sol";
import {IDetailedERC20} from "../../interfaces/IDetailedERC20.sol";

import "hardhat/console.sol";


/// @title Pool
///
/// @dev A library which provides the Pool data struct and associated functions.
library Pool {
  using FixedPointMath for FixedPointMath.FixedDecimal;
  using Pool for Pool.Data;
  using Pool for Pool.List;
  using SafeMath for uint256;

  struct Context {
    uint256 rewardRate;
    uint256 totalRewardWeight;
  }

  struct Data {
    IERC20 token;
    uint256 totalDeposited;
    uint256 rewardWeight;
    FixedPointMath.FixedDecimal accumulatedRewardWeight;
    uint256 lastUpdatedBlock;
  }

  struct List {
    Data[] elements;
  }

  /// @dev Updates the pool.
  ///
  /// @param _ctx the pool context.
  function update(Data storage _data, Context storage _ctx) internal {
    _data.accumulatedRewardWeight = _data.getUpdatedAccumulatedRewardWeight(_ctx);
    _data.lastUpdatedBlock = block.number;
  }

  /// @dev Gets the rate at which the pool will distribute rewards to stakers.
  ///
  /// @param _ctx the pool context.
  ///
  /// @return the reward rate of the pool in tokens per block.
  function getRewardRate(Data storage _data, Context storage _ctx)
    internal view
    returns (uint256)
  {
    // console.log("get reward rate");
    // console.log(uint(_data.rewardWeight));
    // console.log(uint(_ctx.totalRewardWeight));
    // console.log(uint(_ctx.rewardRate));
    return _ctx.rewardRate.mul(_data.rewardWeight).div(_ctx.totalRewardWeight);
  }

  /// @dev Gets the accumulated reward weight of a pool.
  ///
  /// @param _ctx the pool context.
  ///
  /// @return the accumulated reward weight.
  function getUpdatedAccumulatedRewardWeight(Data storage _data, Context storage _ctx)
    internal view
    returns (FixedPointMath.FixedDecimal memory)
  {
    if (_data.totalDeposited == 0) {
      return _data.accumulatedRewardWeight;
    }

    uint256 _elapsedTime = block.number.sub(_data.lastUpdatedBlock);
    if (_elapsedTime == 0) {
      return _data.accumulatedRewardWeight;
    }

    uint256 _rewardRate = _data.getRewardRate(_ctx);
    uint256 _distributeAmount = _rewardRate.mul(_elapsedTime);

    if (_distributeAmount == 0) {
      return _data.accumulatedRewardWeight;
    }

    FixedPointMath.FixedDecimal memory _rewardWeight = FixedPointMath.fromU256(_distributeAmount).div(_data.totalDeposited);
    return _data.accumulatedRewardWeight.add(_rewardWeight);
  }

  /// @dev Adds an element to the list.
  ///
  /// @param _element the element to add.
  function push(List storage _self, Data memory _element) internal {
    _self.elements.push(_element);
  }

  /// @dev Gets an element from the list.
  ///
  /// @param _index the index in the list.
  ///
  /// @return the element at the specified index.
  function get(List storage _self, uint256 _index) internal view returns (Data storage) {
    return _self.elements[_index];
  }

  /// @dev Gets the last element in the list.
  ///
  /// This function will revert if there are no elements in the list.
  ///ck
  /// @return the last element in the list.
  function last(List storage _self) internal view returns (Data storage) {
    return _self.elements[_self.lastIndex()];
  }

  /// @dev Gets the index of the last element in the list.
  ///
  /// This function will revert if there are no elements in the list.
  ///
  /// @return the index of the last element.
  function lastIndex(List storage _self) internal view returns (uint256) {
    uint256 _length = _self.length();
    return _length.sub(1, "Pool.List: list is empty");
  }

  /// @dev Gets the number of elements in the list.
  ///
  /// @return the number of elements.
  function length(List storage _self) internal view returns (uint256) {
    return _self.elements.length;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {FixedPointMath} from "../libraries/FixedPointMath.sol";
import {IDetailedERC20} from "../interfaces/IDetailedERC20.sol";
import {IVaultAdapter} from "../interfaces/IVaultAdapter.sol";
import {IyVaultV2} from "../interfaces/IyVaultV2.sol";

/// @title YearnVaultAdapter
///
/// @dev A vault adapter implementation which wraps a yEarn vault.
contract YearnVaultAdapter is IVaultAdapter {
  using FixedPointMath for FixedPointMath.FixedDecimal;
  using SafeERC20 for IDetailedERC20;
  using SafeMath for uint256;

  /// @dev The vault that the adapter is wrapping.
  IyVaultV2 public vault;

  /// @dev The address which has admin control over this contract.
  address public admin;

  /// @dev The decimals of the token.
  uint256 public decimals;

  constructor(IyVaultV2 _vault, address _admin) public {
    vault = _vault;
    admin = _admin;
    updateApproval();
    decimals = _vault.decimals();
  }

  /// @dev A modifier which reverts if the caller is not the admin.
  modifier onlyAdmin() {
    require(admin == msg.sender, "YearnVaultAdapter: only admin");
    _;
  }

  /// @dev Gets the token that the vault accepts.
  ///
  /// @return the accepted token.
  function token() external view override returns (IDetailedERC20) {
    return IDetailedERC20(vault.token());
  }

  /// @dev Gets the total value of the assets that the adapter holds in the vault.
  ///
  /// @return the total assets.
  function totalValue() external view override returns (uint256) {
    return _sharesToTokens(vault.balanceOf(address(this)));
  }

  /// @dev Deposits tokens into the vault.
  ///
  /// @param _amount the amount of tokens to deposit into the vault.
  function deposit(uint256 _amount) external override {
    vault.deposit(_amount);
  }

  /// @dev Withdraws tokens from the vault to the recipient.
  ///
  /// This function reverts if the caller is not the admin.
  ///
  /// @param _recipient the account to withdraw the tokes to.
  /// @param _amount    the amount of tokens to withdraw.
  function withdraw(address _recipient, uint256 _amount) external override onlyAdmin {
    vault.withdraw(_tokensToShares(_amount),_recipient);
  }

  /// @dev Updates the vaults approval of the token to be the maximum value.
  function updateApproval() public {
    address _token = vault.token();
    IDetailedERC20(_token).safeApprove(address(vault), uint256(-1));
  }

  /// @dev Computes the number of tokens an amount of shares is worth.
  ///
  /// @param _sharesAmount the amount of shares.
  ///
  /// @return the number of tokens the shares are worth.
  
  function _sharesToTokens(uint256 _sharesAmount) internal view returns (uint256) {
    return _sharesAmount.mul(vault.pricePerShare()).div(10**decimals);
  }

  /// @dev Computes the number of shares an amount of tokens is worth.
  ///
  /// @param _tokensAmount the amount of shares.
  ///
  /// @return the number of shares the tokens are worth.
  function _tokensToShares(uint256 _tokensAmount) internal view returns (uint256) {
    return _tokensAmount.mul(10**decimals).div(vault.pricePerShare());
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IyVaultV2 is IERC20 {
    function token() external view returns (address);
    function deposit() external returns (uint);
    function deposit(uint) external returns (uint);
    function deposit(uint, address) external returns (uint);
    function withdraw() external returns (uint);
    function withdraw(uint) external returns (uint);
    function withdraw(uint, address) external returns (uint);
    function withdraw(uint, address, uint) external returns (uint);
    function permit(address, address, uint, uint, bytes32) external view returns (bool);
    function pricePerShare() external view returns (uint);
    
    function apiVersion() external view returns (string memory);
    function totalAssets() external view returns (uint);
    function maxAvailableShares() external view returns (uint);
    function debtOutstanding() external view returns (uint);
    function debtOutstanding(address strategy) external view returns (uint);
    function creditAvailable() external view returns (uint);
    function creditAvailable(address strategy) external view returns (uint);
    function availableDepositLimit() external view returns (uint);
    function expectedReturn() external view returns (uint);
    function expectedReturn(address strategy) external view returns (uint);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint);
    function balanceOf(address owner) external view override returns (uint);
    function totalSupply() external view override returns (uint);
    function governance() external view returns (address);
    function management() external view returns (address);
    function guardian() external view returns (address);
    function guestList() external view returns (address);
    function strategies(address) external view returns (uint, uint, uint, uint, uint, uint, uint, uint);
    function withdrawalQueue(uint) external view returns (address);
    function emergencyShutdown() external view returns (bool);
    function depositLimit() external view returns (uint);
    function debtRatio() external view returns (uint);
    function totalDebt() external view returns (uint);
    function lastReport() external view returns (uint);
    function activation() external view returns (uint);
    function rewards() external view returns (address);
    function managementFee() external view returns (uint);
    function performanceFee() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import '@openzeppelin/contracts/access/Ownable.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';

interface IERC20 {
    function decimals() external view returns (uint256);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns ( address );
    function token1() external view returns ( address );
}

contract GsdPriceAggregator is Ownable {
    using SafeMath for uint256;

    address public GSD = 0xCc871DbBC556ec9c3794152Ae30178085b25fa26;
    address public pair = 0x7235B4A839e28F4228a7b4d1925B1DA75b0C81D1;

    uint256 public GSD_DECIMALS = 9;
    uint256 public USD_DECIMALS = 18;
    uint256 public FEED_DECIMALS = 8;

    uint256 private _price;
    uint256 private _lastUpdated;

    constructor () public {
        updatePrice();
    }

    function aggregate() public view returns(uint256 price, uint256 lastUpdated, uint256 currentPrice) {
        price = _price;
        lastUpdated = _lastUpdated;

        ( uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair).getReserves();
        if (IUniswapV2Pair(pair).token0() == GSD) {
            currentPrice = reserve1.div( 10 ** USD_DECIMALS).div(reserve0.div( 10 ** GSD_DECIMALS)).mul( 10 ** FEED_DECIMALS);
        } else {
            currentPrice = reserve0.div( 10 ** USD_DECIMALS).div(reserve1.div( 10 ** GSD_DECIMALS)).mul( 10 ** FEED_DECIMALS);
        }
    }

    function updatePrice() public onlyOwner {
        ( uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair).getReserves();

        if (IUniswapV2Pair(pair).token0() == GSD) {
            _price = reserve1.div( 10 ** USD_DECIMALS).div(reserve0.div( 10 ** GSD_DECIMALS)).mul( 10 ** FEED_DECIMALS);
        } else {
            _price = reserve0.div( 10 ** USD_DECIMALS).div(reserve1.div( 10 ** GSD_DECIMALS)).mul( 10 ** FEED_DECIMALS);
        }

        _lastUpdated = block.timestamp;
    }

    function updatePool(address _pair, address _gsd) public onlyOwner {
        require(address(_pair) != address(0), "pair address cannot be zero");
        pair = _pair;
        GSD = _gsd;

        if (IUniswapV2Pair(_pair).token0() == _gsd) {
            GSD_DECIMALS = IERC20(IUniswapV2Pair(_pair).token0()).decimals();
            USD_DECIMALS = IERC20(IUniswapV2Pair(_pair).token1()).decimals();
        } else {
            GSD_DECIMALS = IERC20(IUniswapV2Pair(_pair).token1()).decimals();
            USD_DECIMALS = IERC20(IUniswapV2Pair(_pair).token0()).decimals();
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity = 0.6.12;

// The following adapter allows the manager to invest in several stablecoins:
// USDC, USDC.e, USDT.e, DAI.e accross Alpha Homora V2.

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import  "./interfaces/IDetailedERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import {ISafeBox} from "./interfaces/ISafeBox.sol";
import "./interfaces/IHomoraBank.sol";
import "./interfaces/IHomoraComptroller.sol";
import "./interfaces/IJoeRouter.sol";

contract LaValleta {

    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IDetailedERC20;
    using SafeMath for uint256;

    uint256 public constant expScale = 1e18;

    struct AssetInfo {
        address ibAsset;
        address ironBank;
        uint256 decimals;
        uint256 capital;
        uint256 txCosts;
    }

    EnumerableSet.AddressSet internal _assets;
    mapping(address => AssetInfo) public assetInfo;

    address public Comptroller; // Address: 0x2eE80614Ccbc5e28654324a66A396458Fa5cD7Cc
    address public JoeRouter;

    address public manager; // Manager can allocate assets among different stablecoin pools.
    address public immutable caller; // Caller can deposit and withdraw externally.

    constructor(address _ibUSDC, address _comptroller, address _joeRouter, address _caller, address _manager) public {
        require(_ibUSDC != address(0), "Error: Cannot be the null address");
        require(_comptroller != address(0), "Error: Cannot be the null address");
        require(_joeRouter != address(0), "Error: Cannot be the null address");
        require(_caller != address(0), "Error: Cannot be the null address");
        require(_manager != address(0), "Error: Cannot be the null address");

        Comptroller = _comptroller;
        JoeRouter = _joeRouter;

        manager = _manager;
        caller = _caller;

        address _usdc = address(ISafeBox(_ibUSDC).uToken()); 
        address _usdcIronBank = address(ISafeBox(_ibUSDC).cToken());

        _addAsset(_usdc, _ibUSDC, _usdcIronBank, IDetailedERC20(_usdc).decimals());
    }

    // Public methods.
    function token() external view returns (IDetailedERC20) {
        return IDetailedERC20(_assets.at(0));
    }

    function assetsLength() external view returns (uint256) {
        return _assets.length();
    }

    function getAssetAmount(address asset) public view returns (uint256 assetAmount, uint256 assetCapital, uint256 assetInterest) {
        require(_assets.contains(asset), "Error: Asset is not registered");

        address ibAsset = assetInfo[asset].ibAsset;
        address assetIronBank = assetInfo[asset].ironBank;
        //uint256 decimals = assetInfo[asset].decimals;

        uint256 ibBalance = IDetailedERC20(ibAsset).balanceOf(address(this));
        uint256 exchangeRate = IHomoraBank(assetIronBank).exchangeRateStored();
        
        assetAmount = _mulScalarTruncate(ibBalance, exchangeRate);
        assetCapital = assetInfo[asset].capital;

        if(assetAmount < assetCapital) {
            assetInterest = 0;
        } else {
            assetInterest = assetAmount.sub(assetCapital);
        }
    }

    function totalValue() external view returns (uint256) {
        uint256 totalAmount;
        uint256 totalAssets = _assets.length();

        address usdc = _assets.at(0);

        for (uint256 i = 0; i < totalAssets; i++) {
            address asset = _assets.at(i);
            (uint256 assetAmount,,) = getAssetAmount(asset); 
            uint256 decimals = assetInfo[asset].decimals;

            if(decimals > assetInfo[usdc].decimals) {
                assetAmount = assetAmount.div(10 ** (decimals.sub(assetInfo[usdc].decimals)));
            }
            
            totalAmount = totalAmount.add(assetAmount);
        }

        return totalAmount;
    }

    function _getCurrentAssetAmount(address asset) internal returns (uint256 assetAmount, uint256 assetCapital, uint256 assetInterest) {
        require(_assets.contains(asset), "Error: Asset is not registered");

        address ibAsset = assetInfo[asset].ibAsset;
        address assetIronBank = assetInfo[asset].ironBank;
        //uint256 decimals = assetInfo[asset].decimals;

        uint256 ibBalance = IDetailedERC20(ibAsset).balanceOf(address(this));
        uint256 exchangeRate = IHomoraBank(assetIronBank).exchangeRateCurrent();

        _adjustCapital(asset, exchangeRate);
        
        assetAmount = _mulScalarTruncate(ibBalance, exchangeRate);
        assetCapital = assetInfo[asset].capital;

        if(assetAmount < assetCapital) {
            assetInterest = 0;
        } else {
            assetInterest = assetAmount.sub(assetCapital);
        }    
    }

    function totalCurrentValue() public returns (uint256) {
        uint256 totalAmount;
        uint256 totalAssets = _assets.length();

        address usdc = _assets.at(0);

        for (uint256 i = 0; i < totalAssets; i++) {
            address asset = _assets.at(i);
            (uint256 assetAmount,,) = _getCurrentAssetAmount(asset); 
            uint256 decimals = assetInfo[asset].decimals;

            if(decimals > assetInfo[usdc].decimals) {
                assetAmount = assetAmount.div(10 ** (decimals.sub(assetInfo[usdc].decimals)));
            }
            
            totalAmount = totalAmount.add(assetAmount);
        }

        return totalAmount;        
    }

    function portfolioShares() external view returns(address[] memory, uint256[] memory) {
        // Shares of total capital invested on each asset.
        uint256 totalAmount;
        uint256 totalAssets = _assets.length();

        address usdc = _assets.at(0);

        address[] memory assets = new address[](totalAssets);
        uint256[] memory shares = new uint256[](totalAssets);

        for(uint256 i = 0; i < totalAssets; i++) {
            address asset = _assets.at(i);
            uint256 assetAmount = assetInfo[asset].capital;
            uint256 assetDecimals = assetInfo[asset].decimals;

            if(assetDecimals > assetInfo[usdc].decimals) {
                assetAmount = assetAmount.div(10 ** (assetDecimals.sub(assetInfo[usdc].decimals)));
            }

            assets[i] = asset;
            shares[i] = assetAmount;

            totalAmount = totalAmount.add(assetAmount);
        }

        for(uint256 i = 0; i < totalAssets; i++) {
            shares[i] = (shares[i].mul(expScale)).div(totalAmount);
        }

        return (assets, shares);
    }







    // Caller methods
    function deposit(uint256 amount) external {
        require(msg.sender == caller, "Error: Msg sender is not allowed");

        address usdc = _assets.at(0);

        //_adjustCapital(usdc, 0); Maybe not needed

        IDetailedERC20(usdc).safeTransferFrom(msg.sender, address(this), amount);
        
        _deposit(usdc, amount, true);
    }

    function withdraw(address recipient, uint256 amount, bool isCapital) external {
        require(msg.sender == caller, "Error: Msg sender is not allowed");

        address usdc = _assets.at(0);

        _adjustCapital(usdc, 0);
        _withdraw(usdc, recipient, amount, isCapital);
    }


    // Manager methods.
    function setManager(address _newManager) external {
        require(msg.sender == manager, "Error: Msg sender is not the manager");
        require(_newManager != address(0), "Error: Cannot be the null address");

        manager = _newManager;
    }

    function addAsset(address ibAsset) external {
        require(msg.sender == manager, "Error: Msg sender is not the manager");
        require(ibAsset != address(0), "Error: Cannot be the null address");

        address asset = address(ISafeBox(ibAsset).uToken()); 
        address assetIronBank = address(ISafeBox(ibAsset).cToken());
        require(assetInfo[asset].decimals == 0, "Error: Asset already registered");

        uint256 decimals = IDetailedERC20(asset).decimals();
        require(decimals >= assetInfo[_assets.at(0)].decimals, "Error: Less decimals than USDC");

        _addAsset(asset, ibAsset, assetIronBank, decimals);
    }

    function removeAsset(address ibAsset) external {
        require(msg.sender == manager, "Error: Msg sender is not the manager");
        require(ibAsset != address(0), "Error: Cannot be the null address");

        address asset = address(ISafeBox(ibAsset).uToken()); 

        _removeAsset(asset);
    }

    function allocate(address fromAsset, address toAsset, address[] memory path, uint256 amount) external {
        require(msg.sender == manager, "Error: Msg sender is not the manager");

        require(_assets.contains(fromAsset), "Error: Asset is not registered");
        require(_assets.contains(toAsset), "Error: Asset is not registered");
        require(path[path.length - 1] == toAsset, "Error: Asset is not swap output");

        uint256 amountBefore = IDetailedERC20(fromAsset).balanceOf(address(this));

        _adjustCapital(fromAsset, 0);

        AssetInfo storage fromInfo =  assetInfo[fromAsset];
        AssetInfo storage toInfo =  assetInfo[toAsset];

        uint256 fromAssetCapitalBefore = fromInfo.capital;
        uint256 toAssetCapitalBefore = toInfo.capital;

        _withdraw(fromAsset, address(this), amount, true);
        uint256 amountAfter = IDetailedERC20(fromAsset).balanceOf(address(this));

        uint256 amountSwap = amountAfter.sub(amountBefore);

        IDetailedERC20(fromAsset).approve(JoeRouter, amountSwap);
        uint256[] memory _amounts = IJoeRouter(JoeRouter).swapExactTokensForTokens(amountSwap, 0, path, address(this), block.timestamp);

        _deposit(toAsset, _amounts[_amounts.length - 1], true);

        // Account tx costs.
        uint256 fromAssetCapitalAfter = fromInfo.capital;
        uint256 toAssetCapitalAfter = toInfo.capital;
    
        uint256 fromAssetDifference = fromAssetCapitalBefore.sub(fromAssetCapitalAfter);
        uint256 toAssetDifference = toAssetCapitalAfter.sub(toAssetCapitalBefore);

        if(fromInfo.decimals != toInfo.decimals) {
            fromAssetDifference = fromAssetDifference.mul(10 ** toInfo.decimals).div(10 ** fromInfo.decimals);
        }
        
        toInfo.txCosts = toInfo.txCosts.add(fromAssetDifference.sub(toAssetDifference));
    }

    function claimInterest(address asset, address[] memory path) external {
        // Collects interest amount from each pool and deposits it on the USDC pool.
        require(msg.sender == manager, "Error: Msg sender is not the manager");
        require(_assets.contains(asset), "Error: Asset is not registered");

        uint256 totalAssets = _assets.length();

        uint256 usdcAmountBefore = IDetailedERC20(_assets.at(0)).balanceOf(address(this));

        for (uint256 i = 1; i < totalAssets; i++) {
            // Quantify interest amount.
            address ibAsset = assetInfo[asset].ibAsset;
            address assetIronBank = assetInfo[asset].ironBank;

            uint256 cBalance = IDetailedERC20(ibAsset).balanceOf(address(this));
            uint256 exchangeRate = IHomoraBank(assetIronBank).exchangeRateCurrent();
            uint256 assetAmount = _mulScalarTruncate(cBalance, exchangeRate);

            (uint256 assetCapital,) = _adjustCapital(_assets.at(i), exchangeRate);
            uint256 interestAmount = assetAmount.sub(assetCapital);

            // Withdraw interest amount.
            _withdraw(asset, address(this), interestAmount, false);

            // Swap interest amount for USDC.
            IDetailedERC20(asset).approve(JoeRouter, interestAmount);
            IJoeRouter(JoeRouter).swapExactTokensForTokens(interestAmount, 0, path, address(this), block.timestamp);
        }

        // Deposit in USDC pool.
        uint256 usdcAmountAfter = IDetailedERC20(_assets.at(0)).balanceOf(address(this));
        _deposit(_assets.at(0), usdcAmountAfter.sub(usdcAmountBefore), false);
    }


    // Internal methods
    function _addAsset(address _asset, address _ibAsset, address _ironBankAsset, uint256 _decimals) internal {
        _assets.add(_asset);
        assetInfo[_asset] = AssetInfo(_ibAsset, _ironBankAsset, _decimals, 0, 0);
        
        //IHomoraComptroller(Comptroller).enterMarkets(assets);
        IDetailedERC20(_asset).approve(_ibAsset, type(uint256).max);
    }

    function _removeAsset(address _asset) internal {
        _assets.remove(_asset);
        delete assetInfo[_asset];
    }

    function _deposit(address _asset, uint256 _amount, bool isCapital) internal {
        require(_assets.contains(_asset), "Error: Asset is not registered");

        AssetInfo storage _info = assetInfo[_asset];

        address ibAsset = assetInfo[_asset].ibAsset;
        //uint256 status = IHomoraBank(assetBank).mint(_amount);
        ISafeBox(ibAsset).deposit(_amount);

        if(_info.capital > 0) {
            _adjustCapital(_asset, 0);
        }

        if(isCapital) {
            _info.capital = _info.capital.add(_amount);
        }
    }
    
    function _withdraw(address _asset, address _recipient, uint256 _amount, bool isCapital) internal {
        require(_assets.contains(_asset), "Error: Asset is not registered");

        AssetInfo storage _info = assetInfo[_asset];

        address ibAsset = _info.ibAsset;
        uint256 exchangeRate = IHomoraBank(_info.ironBank).exchangeRateCurrent();
        uint256 ibAmount = _divScalarTruncate(_amount, exchangeRate);

        uint256 uBalanceBefore = IDetailedERC20(_asset).balanceOf(address(this));

        //IHomoraBank(assetBank).redeemUnderlying(_amount);
        ISafeBox(ibAsset).withdraw(ibAmount);

        uint256 uBalanceAfter = IDetailedERC20(_asset).balanceOf(address(this));

        uint256 uBalanceDiff = uBalanceAfter.sub(uBalanceBefore);

        if(isCapital) {
            _info.capital = _info.capital.sub(uBalanceDiff);
        } else {
            (, uint256 interestAmount,) = getAssetAmount(_asset); 
            
            if(_amount > interestAmount) {
                _amount = interestAmount;
            }
        }

        if(_recipient != address(this)) {
            IDetailedERC20(_asset).safeTransfer(_recipient, uBalanceDiff);
        }
    }
    
    function _divScalarTruncate(uint256 _uAmount, uint256 _exchangeRate) internal pure returns (uint256) {
        uint256 numerator = _uAmount.mul(expScale);
        uint256 fraction = numerator.div(_exchangeRate);

        return fraction;
    }
    
    function _mulScalarTruncate(uint256 _cAmount, uint256 _exchangeRate) internal pure returns (uint256) {
        uint256 product = _cAmount.mul(_exchangeRate);

        return product.div(expScale);
    }

    function _adjustCapital(address _asset, uint256 _exchangeRate) internal returns (uint256, uint256) {
        // Should return new capital amount + new tx costs amount.
        AssetInfo storage _info = assetInfo[_asset];

        if(_info.txCosts > 0) {
            // Here we should adjust amount.
            uint256 cBalance = IDetailedERC20(_info.ibAsset).balanceOf(address(this));
            uint256 exchangeRate = _exchangeRate;

            if(_exchangeRate == 0) {
                exchangeRate = IHomoraBank(_info.ironBank).exchangeRateCurrent();
            }

            uint256 assetAmount = _mulScalarTruncate(cBalance, exchangeRate);

            uint256 gains = 0;

            if (assetAmount > _info.capital) {
                gains = assetAmount.sub(_info.capital);
            }

            if(gains > _info.txCosts) {
                _info.capital = _info.capital.add(_info.txCosts);
                _info.txCosts = 0;

            } else if (gains > 0) {
                _info.capital = _info.capital.add(gains);
                _info.txCosts = _info.txCosts.sub(gains);

            }
        }

        return (_info.capital, _info.txCosts);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity = 0.6.12;

import "./IDetailedERC20.sol";

interface ISafeBox is IDetailedERC20 {
     function uToken() external view returns(IERC20);
     function cToken() external view returns(IERC20);
     function deposit(uint amount) external;
     function withdraw(uint amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity = 0.6.12;

interface IHomoraBank {
    function exchangeRateCurrent() external returns(uint256);
    function exchangeRateStored() external view returns (uint256);
    function mint(uint256 mintAmount) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity = 0.6.12;

interface IHomoraComptroller {
    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity = 0.6.12;

/*
 * The following methods are part of the IVaultAdapter:
 * function token() external view returns (IDetailedERC20);
 * function totalValue() external view returns (uint256);
 * function deposit(uint256 _amount) external;
 * function withdraw(address _recipient, uint256 _amount) external;
 */

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {IDetailedERC20} from "./interfaces/IDetailedERC20.sol";
import "./interfaces/IHomoraBank.sol";
import "./interfaces/IHomoraComptroller.sol";

/*
 * Steps:
 * A. Approve USDC as done in: https://snowtrace.io/address/0xa0b8adc61e76e2b3961eb66e2e37840e02053591
 * B. Deposit USDC as done in: https://snowtrace.io/tx/0x96044c1741a429b20774be1220d83de7f6f1461e45b23e99da81e8272173406e
 * C. 
 *
 * Iron Bank USDC Coin (CErc20Delegator.sol): 0xEc5Aa19566Aa442C8C50f3C6734b6Bb23fF21CD7
 * ibUSDCv2 token: 0xA0b8aDC61e76e2b3961EB66e2E37840e02053591
 * 
*/

contract AlphaHomoraV2Adapter {

    using SafeERC20 for IDetailedERC20;

    // Change everything from DAI to USDC.
    uint256 public constant expScale = 1e18;

    address public USDC; // 6-decimal token
    address public ibUSDC; // 8-decimal token
    address public IronBank; // Address: 0x085682716f61a72bf8c573fbaf88cca68c60e99b
    address public Comptroller; // Address: 0x2eE80614Ccbc5e28654324a66A396458Fa5cD7Cc
    address public immutable caller;

    constructor (address _usdc, address _ibUSDC, address _ironBank, address _comptroller, address _caller) public {
        require(_usdc != address(0), "Error: Contract cannot be the null address");
        require(_ibUSDC != address(0), "Error: Contract cannot be the null address");
        require(_ironBank != address(0), "Error: Contract cannot be the null address");
        require(_comptroller != address(0), "Error: Contract cannot be the null address");
        require(_caller != address(0), "Error: Contract cannot be the null address");

        USDC = _usdc;
        ibUSDC = _ibUSDC;
        IronBank = _ironBank;
        Comptroller = _comptroller;
        caller = _caller;

        address[] memory asset;
        asset[0] = _usdc;

        IHomoraComptroller(Comptroller).enterMarkets(asset);
    }
    
    function token() external view returns (IDetailedERC20) {
        return IDetailedERC20(USDC);
    }

    function totalValue() external view returns (uint256) {
        uint256 cBalance = IDetailedERC20(ibUSDC).balanceOf(address(this));
        uint256 exchangeRate = IHomoraBank(IronBank).exchangeRateStored();

        return mul_scalarTruncate(cBalance, exchangeRate);
    } // Checked

    function deposit(uint256 amount) external {
        require(msg.sender == caller, "Error: Msg sender is not allowed");
        
        IHomoraBank(IronBank).mint(amount);
    } // Checked

    function withdraw(address recipient, uint256 amount) external {
        require(msg.sender == caller, "Error: Msg sender is not allowed");

        IHomoraBank(IronBank).redeemUnderlying(amount);

        uint256 uBalance = IDetailedERC20(USDC).balanceOf(address(this));
        IDetailedERC20(USDC).safeTransfer(recipient, uBalance);
    }

    function mul_scalarTruncate(uint256 cAmount, uint256 exchangeRate) public pure returns (uint256) {
        uint256 product = cAmount * exchangeRate;
        return product / expScale;
    } // Checked
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity = 0.6.12;
pragma experimental ABIEncoderV2;

// The following adapter allows the manager to invest in several stablecoins:
// USDC, USDC.e, USDT.e, DAI.e accross Alpha Homora V2.

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IDetailedERC20} from "./interfaces/IDetailedERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import {ISafeBox} from "./interfaces/ISafeBox.sol";
import "./interfaces/IHomoraBank.sol";
import "./interfaces/IPlatypusPool.sol"; 
import "hardhat/console.sol";

/*
 * The following methods are part of the IVaultAdapter:
 * function token() external view returns (IDetailedERC20);
 * function totalValue() external view returns (uint256);
 * function deposit(uint256 _amount) external;
 * function withdraw(address _recipient, uint256 _amount) external;
*/

/*
 USDC, USDC.e, USDT.e = 6 decimals.
 DAI.e = 18 decimals.
*/
 
contract AssetManagementHomoraThroughPlatypusAdapter {

    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IDetailedERC20;
    using SafeMath for uint256;

    uint256 public constant expScale = 1e18;

    struct AssetInfo {
        address ibAsset;
        address ironBank;
        uint256 decimals;
        uint256 capital;
        uint256 txCosts;
    }

    EnumerableSet.AddressSet internal _assets;
    mapping(address => AssetInfo) public assetInfo;

    address public immutable PlatypusPool;

    address public manager; // Manager can allocate assets among different stablecoin pools.
    address public immutable caller; // Caller can deposit and withdraw externally.

    event ManagerSet(address newManager);
    event AssetAdded(address _asset);
    event AssetRemoved(address _asset);
    event CapitalAllocated(address _from, address _to, uint256 _fromAmount);
    event InterestClaimed(address _asset, uint256 _interestAmount);

    constructor(address _usdc, address _ibUSDC, address _usdcIronBank, address _PlatypusPool, address _caller, address _manager) public {
        require(_usdc != address(0), "Error: Cannot be the null address");
        require(_ibUSDC != address(0), "Error: Cannot be the null address");
        require(_usdcIronBank != address(0), "Error: Cannot be the null address");
        require(_PlatypusPool != address(0), "Error: Cannot be the null address");
        require(_caller != address(0), "Error: Cannot be the null address");
        require(_manager != address(0), "Error: Cannot be the null address");

        PlatypusPool = _PlatypusPool;

        manager = _manager;
        caller = _caller;

        _addAssetAndEnterMarkets(_usdc, _ibUSDC, _usdcIronBank, IDetailedERC20(_usdc).decimals());
    }

    // Public methods.
    function token() external view returns (IDetailedERC20) {
        return IDetailedERC20(_assets.at(0));
    }

    function assetsLength() external view returns (uint256) {
        return _assets.length();
    }

    function getAssetAmount(address asset) public view returns (uint256 assetAmount, uint256 assetCapital, uint256 assetInterest) {
        require(_assets.contains(asset), "Error: Asset is not registered");

        address ibAsset = assetInfo[asset].ibAsset;
        address assetIronBank = assetInfo[asset].ironBank;

        uint256 ibBalance = IDetailedERC20(ibAsset).balanceOf(address(this));
        uint256 exchangeRate = IHomoraBank(assetIronBank).exchangeRateStored();
        
        assetAmount = _mulScalarTruncate(ibBalance, exchangeRate);
        assetCapital = assetInfo[asset].capital;

        if(assetAmount < assetCapital) {
            assetInterest = 0;
        } else {
            assetInterest = assetAmount.sub(assetCapital);
        }
    }

    function totalValue() external view returns (uint256) {
        uint256 totalAmount;
        uint256 totalAssets = _assets.length();

        address usdc = _assets.at(0);

        for (uint256 i = 0; i < totalAssets; i++) {
            address asset = _assets.at(i);
            (uint256 assetAmount,,) = getAssetAmount(asset); 
            uint256 decimals = assetInfo[asset].decimals;

            if(decimals > assetInfo[usdc].decimals) {
                assetAmount = assetAmount.div(10 ** (decimals.sub(assetInfo[usdc].decimals)));
            }
            
            totalAmount = totalAmount.add(assetAmount);
        }

        return totalAmount;
    }

    function portfolioShares() external view returns(address[] memory, uint256[] memory) {
        // Shares of total capital invested on each asset.
        uint256 totalAmount;
        uint256 totalAssets = _assets.length();

        address usdc = _assets.at(0);

        address[] memory assets = new address[](totalAssets);
        uint256[] memory shares = new uint256[](totalAssets);

        for(uint256 i = 0; i < totalAssets; i++) {
            address asset = _assets.at(i);
            uint256 assetAmount = assetInfo[asset].capital;
            uint256 assetDecimals = assetInfo[asset].decimals;

            if(assetDecimals > assetInfo[usdc].decimals) {
                assetAmount = assetAmount.div(10 ** (assetDecimals.sub(assetInfo[usdc].decimals)));
            }

            assets[i] = asset;
            shares[i] = assetAmount;

            totalAmount = totalAmount.add(assetAmount);
        }

        for(uint256 i = 0; i < totalAssets; i++) {
            shares[i] = (shares[i].mul(expScale)).div(totalAmount);
        }

        return (assets, shares);
    }

    // Caller methods
    function deposit(uint256 amount) external {
        require(msg.sender == caller, "Error: Msg sender is not allowed");

        address usdc = _assets.at(0);

        _adjustCapital(usdc);

        IDetailedERC20(usdc).safeTransferFrom(msg.sender, address(this), amount);
        
        _deposit(usdc, amount, true);
    }

    function withdraw(address recipient, uint256 amount, bool isCapital) external {
        require(msg.sender == caller, "Error: Msg sender is not allowed");

        address usdc = _assets.at(0);

        _adjustCapital(usdc);
        _withdraw(usdc, recipient, amount, isCapital);
    }

    // Manager methods.
    function setManager(address _newManager) external {
        require(msg.sender == manager, "Error: Msg sender is not the manager");
        require(_newManager != address(0), "Error: Cannot be the null address");

        manager = _newManager;

        emit ManagerSet(_newManager);
    }

    function addAsset(address asset, address ibAsset, address assetIronBank) external {
        require(msg.sender == manager, "Error: Msg sender is not the manager");
        require(asset != address(0), "Error: Cannot be the null address");
        require(ibAsset != address(0), "Error: Cannot be the null address");
        require(assetIronBank != address(0), "Error: Cannot be the null address");

        require(assetInfo[asset].decimals == 0, "Error: Asset already registered");

        uint256 decimals = IDetailedERC20(asset).decimals();
        require(decimals >= assetInfo[_assets.at(0)].decimals, "Error: Less decimals than USDC");

        _addAssetAndEnterMarkets(asset, ibAsset, assetIronBank, decimals);
    }

    function removeAsset(address asset) external {
        require(msg.sender == manager, "Error: Msg sender is not the manager");
        require(asset != address(0) || asset != _assets.at(0), "Error: Invalid address");
        require(assetInfo[asset].capital == 0, "Error: Allocated capital in this asset");

        bool check = _assets.remove(asset);
        require(check, "Error: Check reverted");

        delete assetInfo[asset];

        emit AssetRemoved(asset);
    }

    struct AllocInputs {
        address fromAsset;
        address toAsset;
        uint256 amount;
    }

    function allocate(AllocInputs memory input) external {
        require(msg.sender == manager, "Error: Msg sender is not the manager");

        require(_assets.contains(input.fromAsset), "Error: Asset is not registered");
        require(_assets.contains(input.toAsset), "Error: Asset is not registered");
        
        uint256 amountBefore = IDetailedERC20(input.fromAsset).balanceOf(address(this));

        _adjustCapital(input.fromAsset);

        AssetInfo storage fromInfo =  assetInfo[input.fromAsset];
        AssetInfo storage toInfo =  assetInfo[input.toAsset];

        uint256 fromAssetCapitalBefore = fromInfo.capital;
        uint256 toAssetCapitalBefore = toInfo.capital;

        _withdraw(input.fromAsset, address(this), input.amount, true);
        uint256 amountAfter = IDetailedERC20(input.fromAsset).balanceOf(address(this));

        uint256 amountSwap = amountAfter.sub(amountBefore);

        // Swap "fromAsset" amount to toAsset.
        uint256 toAmount = _approveRouterAndExecuteSwap(input.fromAsset, input.toAsset, amountSwap);

        _deposit(input.toAsset, toAmount, true);

        // Account tx costs.
        uint256 fromAssetCapitalAfter = fromInfo.capital;
        uint256 toAssetCapitalAfter = toInfo.capital;
    
        uint256 fromAssetDifference = fromAssetCapitalBefore.sub(fromAssetCapitalAfter); 
        uint256 toAssetDifference = toAssetCapitalAfter.sub(toAssetCapitalBefore); 
        console.log("FromAsset difference:", fromAssetDifference);
        console.log("ToAsset difference:", toAssetDifference);

        if(fromInfo.decimals != toInfo.decimals) {
            fromAssetDifference = fromAssetDifference.mul(10 ** toInfo.decimals).div(10 ** fromInfo.decimals);
        }
        
        // If this difference is positive, it should be registered within toInfo.txCosts.
        if(fromAssetDifference - toAssetDifference < fromAssetDifference) {
            toInfo.txCosts = toInfo.txCosts.add(fromAssetDifference.sub(toAssetDifference));
        }

        emit CapitalAllocated(input.fromAsset, input.toAsset, input.amount);
    }

    function claimInterest(address asset) external {
        // Collects interest amount from each pool and deposits it on the USDC pool.
        require(msg.sender == manager, "Error: Msg sender is not the manager");
        require(_assets.contains(asset), "Error: Asset is not registered");
        
        uint256 usdcAmountBefore = IDetailedERC20(_assets.at(0)).balanceOf(address(this));

        // Asset balance estimation.
        (uint256 assetCapital,) = _adjustCapital(asset);

        // Quantify interest amount.
        address ibAsset = assetInfo[asset].ibAsset;
        address assetIronBank = assetInfo[asset].ironBank;

        uint256 cBalance = IDetailedERC20(ibAsset).balanceOf(address(this));
        uint256 exchangeRate = IHomoraBank(assetIronBank).exchangeRateCurrent();
        uint256 assetAmount = _mulScalarTruncate(cBalance, exchangeRate);

        uint256 interestAmount = assetAmount.sub(assetCapital);

        if(interestAmount != 0) {
            // Withdraw interest amount.
            uint256 assetBefore = IDetailedERC20(asset).balanceOf(address(this));
            _withdraw(asset, address(this), interestAmount, false);
            uint256 assetAfter = IDetailedERC20(asset).balanceOf(address(this));

            // Swap interest amount for USDC.
            address usdc = _assets.at(0);
            _approveRouterAndExecuteSwap(asset, usdc, assetAfter.sub(assetBefore));

            // Deposit in USDC pool.
            uint256 usdcAmountAfter = IDetailedERC20(_assets.at(0)).balanceOf(address(this));
            _deposit(_assets.at(0), usdcAmountAfter.sub(usdcAmountBefore), false);

            emit InterestClaimed(asset, usdcAmountAfter.sub(usdcAmountBefore));
        } else {
            emit InterestClaimed(asset, 0);
        }
    }

    // Internal methods
    function _approveRouterAndExecuteSwap(address fromAsset, address toAsset, uint256 fromAmount) internal returns (uint256) {
        bool check = IDetailedERC20(fromAsset).approve(PlatypusPool, fromAmount); 
        require(check, "Error: Check reverted");

        (uint256 expectedToAmount, ) = IPlatypusPool(PlatypusPool).quotePotentialSwap(fromAsset, toAsset, fromAmount); // For Platypus
        uint256 minAmountAccepted = expectedToAmount.mul(98).div(100);

        (uint256 toAmount, ) = IPlatypusPool(PlatypusPool).swap(fromAsset, toAsset, fromAmount, minAmountAccepted, address(this), block.timestamp); // For Platypus
        require(toAmount >= minAmountAccepted, "Error: Slippage exceeded");

        return toAmount;
    }

    function _addAssetAndEnterMarkets(address _asset, address _ibAsset, address _ironBankAsset, uint256 _decimals) internal {
        bool check = _assets.add(_asset);
        require(check, "Error: Check reverted");

        assetInfo[_asset] = AssetInfo(_ibAsset, _ironBankAsset, _decimals, 0, 0);
        
        check = IDetailedERC20(_asset).approve(_ibAsset, type(uint256).max);
        require(check, "Error: Check reverted");

        emit AssetAdded(_asset);
    }

    function _deposit(address _asset, uint256 _amount, bool isCapital) internal {
        require(_assets.contains(_asset), "Error: Asset is not registered");

        AssetInfo storage _info = assetInfo[_asset];

        address ibAsset = assetInfo[_asset].ibAsset;
        //uint256 status = IHomoraBank(assetBank).mint(_amount);
        ISafeBox(ibAsset).deposit(_amount);

        //console.log("Vault USDC balance after depositing:", IDetailedERC20(_asset).balanceOf(address(this)));

        if(_info.capital > 0) {
            _adjustCapital(_asset);
        }

        if(isCapital) {
            _info.capital = _info.capital.add(_amount);
        }
    }

    function _withdraw(address _asset, address _recipient, uint256 _amount, bool isCapital) internal {
        require(_assets.contains(_asset), "Error: Asset is not registered");

        AssetInfo storage _info = assetInfo[_asset];

        address ibAsset = _info.ibAsset;
        uint256 exchangeRate = IHomoraBank(_info.ironBank).exchangeRateCurrent();
        
        uint256 uBalanceBefore = IDetailedERC20(_asset).balanceOf(address(this));

        if(!isCapital) {
            (,,uint256 interestAmount) = getAssetAmount(_asset); // Big bug here, originally (,uint256 interestAmount,) = getAssetAmount(_asset)
            
            if(_amount > interestAmount) {
                _amount = interestAmount;
            }
        }

        uint256 ibAmount = _divScalarTruncate(_amount, exchangeRate);
        ISafeBox(ibAsset).withdraw(ibAmount);

        uint256 uBalanceAfter = IDetailedERC20(_asset).balanceOf(address(this));
        uint256 uBalanceDiff = uBalanceAfter.sub(uBalanceBefore);

        if(isCapital) {
            _info.capital = _info.capital.sub(uBalanceDiff);           
        }

        if(_recipient != address(this)) {
            IDetailedERC20(_asset).safeTransfer(_recipient, uBalanceDiff);
        }       
    }

    function _divScalarTruncate(uint256 _uAmount, uint256 _exchangeRate) internal pure returns (uint256) {
        uint256 numerator = _uAmount.mul(expScale);
        uint256 fraction = numerator.div(_exchangeRate);

        return fraction;
    }
    
    function _mulScalarTruncate(uint256 _cAmount, uint256 _exchangeRate) internal pure returns (uint256) {
        uint256 product = _cAmount.mul(_exchangeRate);

        return product.div(expScale);
    }

    function _adjustCapital(address _asset) internal returns (uint256, uint256) {
        // Should return new capital amount + new tx costs amount.
        AssetInfo storage _info = assetInfo[_asset];

        if(_info.txCosts > 0) {
            // Here we should adjust amount.
            uint256 cBalance = IDetailedERC20(_info.ibAsset).balanceOf(address(this));
            uint256 exchangeRate = IHomoraBank(_info.ironBank).exchangeRateStored();
            uint256 assetAmount = _mulScalarTruncate(cBalance, exchangeRate);

            uint256 gains = 0;

            if (assetAmount > _info.capital) {
                gains = assetAmount.sub(_info.capital);
            }

            if(gains > _info.txCosts) {
                _info.capital = _info.capital.add(_info.txCosts);
                _info.txCosts = 0;

            } else if (gains > 0) {
                _info.capital = _info.capital.add(gains);
                _info.txCosts = _info.txCosts.sub(gains);

            }
        }

        return (_info.capital, _info.txCosts);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IPlatypusPool {
    
    function quotePotentialSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) external view returns(uint256 potentialOutcome, uint256 haircut);

    function swap(
        address fromToken, 
        address toToken, 
        uint256 fromAmount, 
        uint256 minimumToAmount, 
        address to, 
        uint256 deadline
    ) external returns (uint256 actualToAmount, uint256 haircut);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity = 0.6.12;
pragma experimental ABIEncoderV2;

// The following adapter allows the manager to invest in several stablecoins:
// USDC, USDC.e, USDT.e, DAI.e accross Alpha Homora V2.

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IDetailedERC20} from "./interfaces/IDetailedERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import {ISafeBox} from "./interfaces/ISafeBox.sol";
import "./interfaces/IHomoraBank.sol";
import "./interfaces/IJoeRouter.sol";
import "hardhat/console.sol";

/*
 * The following methods are part of the IVaultAdapter:
 * function token() external view returns (IDetailedERC20);
 * function totalValue() external view returns (uint256);
 * function deposit(uint256 _amount) external;
 * function withdraw(address _recipient, uint256 _amount) external;
*/

/*
 USDC, USDC.e, USDT.e = 6 decimals.
 DAI.e = 18 decimals.
*/
 
contract AssetManagementHomoraAdapter {

    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IDetailedERC20;
    using SafeMath for uint256;

    uint256 public constant expScale = 1e18;

    struct AssetInfo {
        address ibAsset;
        address ironBank;
        uint256 decimals;
        uint256 capital;
        uint256 txCosts;
    }

    EnumerableSet.AddressSet internal _assets;
    mapping(address => AssetInfo) public assetInfo;

    address public immutable JoeRouter;

    address public manager; // Manager can allocate assets among different stablecoin pools.
    address public immutable caller; // Caller can deposit and withdraw externally.

    event ManagerSet(address newManager);
    event AssetAdded(address _asset);
    event AssetRemoved(address _asset);
    event CapitalAllocated(address _from, address _to, uint256 _fromAmount);
    event InterestClaimed(address _asset, uint256 _interestAmount);

    constructor(address _usdc, address _ibUSDC, address _usdcIronBank, address _joeRouter, address _caller, address _manager) public {
        require(_usdc != address(0), "Error: Cannot be the null address");
        require(_ibUSDC != address(0), "Error: Cannot be the null address");
        require(_usdcIronBank != address(0), "Error: Cannot be the null address");
        require(_joeRouter != address(0), "Error: Cannot be the null address");
        require(_caller != address(0), "Error: Cannot be the null address");
        require(_manager != address(0), "Error: Cannot be the null address");

        JoeRouter = _joeRouter;

        manager = _manager;
        caller = _caller;

        _addAssetAndEnterMarkets(_usdc, _ibUSDC, _usdcIronBank, IDetailedERC20(_usdc).decimals());
    }

    // Public methods.
    function token() external view returns (IDetailedERC20) {
        return IDetailedERC20(_assets.at(0));
    }

    function assetsLength() external view returns (uint256) {
        return _assets.length();
    }

    function getAssetAmount(address asset) public view returns (uint256 assetAmount, uint256 assetCapital, uint256 assetInterest) {
        require(_assets.contains(asset), "Error: Asset is not registered");

        address ibAsset = assetInfo[asset].ibAsset;
        address assetIronBank = assetInfo[asset].ironBank;

        uint256 ibBalance = IDetailedERC20(ibAsset).balanceOf(address(this));
        uint256 exchangeRate = IHomoraBank(assetIronBank).exchangeRateStored();
        
        assetAmount = _mulScalarTruncate(ibBalance, exchangeRate);
        assetCapital = assetInfo[asset].capital;

        if(assetAmount < assetCapital) {
            assetInterest = 0;
        } else {
            assetInterest = assetAmount.sub(assetCapital);
        }
    }

    function totalValue() external view returns (uint256) {
        uint256 totalAmount;
        uint256 totalAssets = _assets.length();

        address usdc = _assets.at(0);

        for (uint256 i = 0; i < totalAssets; i++) {
            address asset = _assets.at(i);
            (uint256 assetAmount,,) = getAssetAmount(asset); 
            uint256 decimals = assetInfo[asset].decimals;

            if(decimals > assetInfo[usdc].decimals) {
                assetAmount = assetAmount.div(10 ** (decimals.sub(assetInfo[usdc].decimals)));
            }
            
            totalAmount = totalAmount.add(assetAmount);
        }

        return totalAmount;
    }

    function portfolioShares() external view returns(address[] memory, uint256[] memory) {
        // Shares of total capital invested on each asset.
        uint256 totalAmount;
        uint256 totalAssets = _assets.length();

        address usdc = _assets.at(0);

        address[] memory assets = new address[](totalAssets);
        uint256[] memory shares = new uint256[](totalAssets);

        for(uint256 i = 0; i < totalAssets; i++) {
            address asset = _assets.at(i);
            uint256 assetAmount = assetInfo[asset].capital;
            uint256 assetDecimals = assetInfo[asset].decimals;

            if(assetDecimals > assetInfo[usdc].decimals) {
                assetAmount = assetAmount.div(10 ** (assetDecimals.sub(assetInfo[usdc].decimals)));
            }

            assets[i] = asset;
            shares[i] = assetAmount;

            totalAmount = totalAmount.add(assetAmount);
        }

        for(uint256 i = 0; i < totalAssets; i++) {
            shares[i] = (shares[i].mul(expScale)).div(totalAmount);
        }

        return (assets, shares);
    }

    // Caller methods
    function deposit(uint256 amount) external {
        require(msg.sender == caller, "Error: Msg sender is not allowed");

        address usdc = _assets.at(0);

        _adjustCapital(usdc);

        IDetailedERC20(usdc).safeTransferFrom(msg.sender, address(this), amount);
        
        _deposit(usdc, amount, true);
    }

    function withdraw(address recipient, uint256 amount, bool isCapital) external {
        require(msg.sender == caller, "Error: Msg sender is not allowed");

        address usdc = _assets.at(0);

        _adjustCapital(usdc);
        _withdraw(usdc, recipient, amount, isCapital);
    }

    // Manager methods.
    function setManager(address _newManager) external {
        require(msg.sender == manager, "Error: Msg sender is not the manager");
        require(_newManager != address(0), "Error: Cannot be the null address");

        manager = _newManager;

        emit ManagerSet(_newManager);
    }

    function addAsset(address asset, address ibAsset, address assetIronBank) external {
        require(msg.sender == manager, "Error: Msg sender is not the manager");
        require(asset != address(0), "Error: Cannot be the null address");
        require(ibAsset != address(0), "Error: Cannot be the null address");
        require(assetIronBank != address(0), "Error: Cannot be the null address");

        require(assetInfo[asset].decimals == 0, "Error: Asset already registered");

        uint256 decimals = IDetailedERC20(asset).decimals();
        require(decimals >= assetInfo[_assets.at(0)].decimals, "Error: Less decimals than USDC");

        _addAssetAndEnterMarkets(asset, ibAsset, assetIronBank, decimals);
    }

    function removeAsset(address asset) external {
        require(msg.sender == manager, "Error: Msg sender is not the manager");
        require(asset != address(0) || asset != _assets.at(0), "Error: Invalid address");
        require(assetInfo[asset].capital == 0, "Error: Allocated capital in this asset");

        bool check = _assets.remove(asset);
        require(check, "Error: Check reverted");

        delete assetInfo[asset];

        emit AssetRemoved(asset);
    }

    struct AllocInputs {
        address fromAsset;
        address toAsset;
        address[] path;
        uint256 amount;
    }

    function allocate(AllocInputs memory input) external {
        require(msg.sender == manager, "Error: Msg sender is not the manager");

        require(_assets.contains(input.fromAsset), "Error: Asset is not registered");
        require(_assets.contains(input.toAsset), "Error: Asset is not registered");
        
        require(input.path[0] == input.fromAsset, "Error: Asset is not swap input");
        require(input.path[input.path.length - 1] == input.toAsset, "Error: Asset is not swap output");

        uint256 amountBefore = IDetailedERC20(input.fromAsset).balanceOf(address(this));

        _adjustCapital(input.fromAsset);

        AssetInfo storage fromInfo =  assetInfo[input.fromAsset];
        AssetInfo storage toInfo =  assetInfo[input.toAsset];

        uint256 fromAssetCapitalBefore = fromInfo.capital;
        uint256 toAssetCapitalBefore = toInfo.capital;

        _withdraw(input.fromAsset, address(this), input.amount, true);
        uint256 amountAfter = IDetailedERC20(input.fromAsset).balanceOf(address(this));

        uint256 amountSwap = amountAfter.sub(amountBefore);

        // Swap "fromAsset" amount to toAsset.
        uint256 toAmount = _approveRouterAndExecuteSwap(input.fromAsset, input.path, amountSwap);

        _deposit(input.toAsset, toAmount, true);

        // Account tx costs.
        uint256 fromAssetCapitalAfter = fromInfo.capital;
        uint256 toAssetCapitalAfter = toInfo.capital;
    
        uint256 fromAssetDifference = fromAssetCapitalBefore.sub(fromAssetCapitalAfter); 
        uint256 toAssetDifference = toAssetCapitalAfter.sub(toAssetCapitalBefore); 
        console.log("FromAsset difference:", fromAssetDifference);
        console.log("ToAsset difference:", toAssetDifference);

        if(fromInfo.decimals != toInfo.decimals) {
            fromAssetDifference = fromAssetDifference.mul(10 ** toInfo.decimals).div(10 ** fromInfo.decimals);
        }
        
        // If this difference is positive, it should be registered within toInfo.txCosts.
        if(fromAssetDifference - toAssetDifference < fromAssetDifference) {
            toInfo.txCosts = toInfo.txCosts.add(fromAssetDifference.sub(toAssetDifference));
        }

        emit CapitalAllocated(input.fromAsset, input.toAsset, input.amount);
    }

    function claimInterest(address asset, address[] memory path) external {
        // Collects interest amount from each pool and deposits it on the USDC pool.
        require(msg.sender == manager, "Error: Msg sender is not the manager");
        require(_assets.contains(asset), "Error: Asset is not registered");
        require(path[0] == asset, "Error: Asset is not swap input");
        require(path[path.length - 1] == _assets.at(0), "Error: Asset is not swap output");
        
        uint256 usdcAmountBefore = IDetailedERC20(_assets.at(0)).balanceOf(address(this));

        // Asset balance estimation.
        (uint256 assetCapital,) = _adjustCapital(asset);

        // Quantify interest amount.
        address ibAsset = assetInfo[asset].ibAsset;
        address assetIronBank = assetInfo[asset].ironBank;

        uint256 cBalance = IDetailedERC20(ibAsset).balanceOf(address(this));
        uint256 exchangeRate = IHomoraBank(assetIronBank).exchangeRateCurrent();
        uint256 assetAmount = _mulScalarTruncate(cBalance, exchangeRate);

        uint256 interestAmount = assetAmount.sub(assetCapital);

        if(interestAmount != 0) {
            // Withdraw interest amount.
            uint256 assetBefore = IDetailedERC20(asset).balanceOf(address(this));
            _withdraw(asset, address(this), interestAmount, false);
            uint256 assetAfter = IDetailedERC20(asset).balanceOf(address(this));

            // Swap interest amount for USDC.
            _approveRouterAndExecuteSwap(asset, path, assetAfter.sub(assetBefore));

            // Deposit in USDC pool.
            uint256 usdcAmountAfter = IDetailedERC20(_assets.at(0)).balanceOf(address(this));
            _deposit(_assets.at(0), usdcAmountAfter.sub(usdcAmountBefore), false);

            emit InterestClaimed(asset, usdcAmountAfter.sub(usdcAmountBefore));
        } else {
            emit InterestClaimed(asset, 0);
        }
    }

    // Internal methods
    function _approveRouterAndExecuteSwap(address fromAsset, address[] memory path, uint256 fromAmount) internal returns (uint256) {
        bool check = IDetailedERC20(fromAsset).approve(JoeRouter, fromAmount); 
        require(check, "Error: Check reverted");

        uint256[] memory amounts = IJoeRouter(JoeRouter).getAmountsOut(fromAmount, path);
        uint256 minAmountAccepted = amounts[amounts.length - 1].mul(95).div(100);

        uint256[] memory _amounts = IJoeRouter(JoeRouter).swapExactTokensForTokens(fromAmount, minAmountAccepted, path, address(this), block.timestamp);
        require(_amounts[_amounts.length - 1] >= minAmountAccepted, "Error: Slippage exceeded");

        return _amounts[_amounts.length - 1];
    }

    function _addAssetAndEnterMarkets(address _asset, address _ibAsset, address _ironBankAsset, uint256 _decimals) internal {
        bool check = _assets.add(_asset);
        require(check, "Error: Check reverted");

        assetInfo[_asset] = AssetInfo(_ibAsset, _ironBankAsset, _decimals, 0, 0);
        
        check = IDetailedERC20(_asset).approve(_ibAsset, type(uint256).max);
        require(check, "Error: Check reverted");

        emit AssetAdded(_asset);
    }

    function _deposit(address _asset, uint256 _amount, bool isCapital) internal {
        require(_assets.contains(_asset), "Error: Asset is not registered");

        AssetInfo storage _info = assetInfo[_asset];

        address ibAsset = assetInfo[_asset].ibAsset;
        //uint256 status = IHomoraBank(assetBank).mint(_amount);
        ISafeBox(ibAsset).deposit(_amount);

        //console.log("Vault USDC balance after depositing:", IDetailedERC20(_asset).balanceOf(address(this)));

        if(_info.capital > 0) {
            _adjustCapital(_asset);
        }

        if(isCapital) {
            _info.capital = _info.capital.add(_amount);
        }
    }

    function _withdraw(address _asset, address _recipient, uint256 _amount, bool isCapital) internal {
        require(_assets.contains(_asset), "Error: Asset is not registered");

        AssetInfo storage _info = assetInfo[_asset];

        address ibAsset = _info.ibAsset;
        uint256 exchangeRate = IHomoraBank(_info.ironBank).exchangeRateCurrent();
        
        uint256 uBalanceBefore = IDetailedERC20(_asset).balanceOf(address(this));

        if(!isCapital) {
            (,,uint256 interestAmount) = getAssetAmount(_asset); // Big bug here, originally (,uint256 interestAmount,) = getAssetAmount(_asset)
            
            if(_amount > interestAmount) {
                _amount = interestAmount;
            }
        }

        uint256 ibAmount = _divScalarTruncate(_amount, exchangeRate);
        ISafeBox(ibAsset).withdraw(ibAmount);

        uint256 uBalanceAfter = IDetailedERC20(_asset).balanceOf(address(this));
        uint256 uBalanceDiff = uBalanceAfter.sub(uBalanceBefore);

        if(isCapital) {
            _info.capital = _info.capital.sub(uBalanceDiff);           
        }

        if(_recipient != address(this)) {
            IDetailedERC20(_asset).safeTransfer(_recipient, uBalanceDiff);
        }       
    }

    function _divScalarTruncate(uint256 _uAmount, uint256 _exchangeRate) internal pure returns (uint256) {
        uint256 numerator = _uAmount.mul(expScale);
        uint256 fraction = numerator.div(_exchangeRate);

        return fraction;
    }
    
    function _mulScalarTruncate(uint256 _cAmount, uint256 _exchangeRate) internal pure returns (uint256) {
        uint256 product = _cAmount.mul(_exchangeRate);

        return product.div(expScale);
    }

    function _adjustCapital(address _asset) internal returns (uint256, uint256) {
        // Should return new capital amount + new tx costs amount.
        AssetInfo storage _info = assetInfo[_asset];

        if(_info.txCosts > 0) {
            // Here we should adjust amount.
            uint256 cBalance = IDetailedERC20(_info.ibAsset).balanceOf(address(this));
            uint256 exchangeRate = IHomoraBank(_info.ironBank).exchangeRateStored();
            uint256 assetAmount = _mulScalarTruncate(cBalance, exchangeRate);

            uint256 gains = 0;

            if (assetAmount > _info.capital) {
                gains = assetAmount.sub(_info.capital);
            }

            if(gains > _info.txCosts) {
                _info.capital = _info.capital.add(_info.txCosts);
                _info.txCosts = 0;

            } else if (gains > 0) {
                _info.capital = _info.capital.add(gains);
                _info.txCosts = _info.txCosts.sub(gains);

            }
        }

        return (_info.capital, _info.txCosts);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IGSERC721 is IERC721 {
    function mint(address to, string calldata tokenURI, uint256 gsEquivalence) external;
    function burn(uint256 tokenId) external;
    function getGSValue(uint256 tokenId) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
// Note: internal audit passed.
// Post audit comments: anyone should be able to list tokens. If marketplace is selling, par value is burned.
pragma solidity =0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IERC20Burnable.sol";
import "./interfaces/IGSERC721.sol";

import "hardhat/console.sol";

contract GSNFTMarketplace is Ownable, Pausable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public immutable GSD;
    address public immutable gsERC721;

    struct TokenForSale {
        address owner;
        address operator;
        bool listed;
        uint256 price;
    }

    mapping(uint256 => TokenForSale) public listing;

    event TokenListed(address owner, uint256 tokenId, uint256 price);
    event TokenPurchased(address buyer, uint256 tokenId, uint256 pricePaid);
    event TokenUnlisted(uint256 tokenId);
    event TokenPriceChanged(uint256 tokenId, uint256 newPrice);

    constructor(address _gsdToken, address _nft) public {
        require(_gsdToken != address(0), "Error: Cannot be the null address");
        require(_nft != address(0), "Error: Cannot be the null address");

        GSD = _gsdToken;
        gsERC721 = _nft;
    }

    function list(uint256 tokenId, uint256 price) external {
        address caller = _msgSender();
        address tokenOwner = IGSERC721(gsERC721).ownerOf(tokenId);

        require(!listing[tokenId].listed, "Error: Token ID already listed");

        if(tokenOwner == address(this)) {
            require(caller == owner(), "Ownable: caller is not the owner");
        } else {
            require(tokenOwner == caller || IGSERC721(gsERC721).getApproved(tokenId) == caller || IGSERC721(gsERC721).isApprovedForAll(tokenOwner, caller) == true, "Error: Caller is not owner or approved");
        }

        listing[tokenId].owner = tokenOwner;
        listing[tokenId].operator = caller;
        listing[tokenId].listed = true;
        setPrice(tokenId, price);

        if (tokenOwner != address(this)) {
            IGSERC721(gsERC721).safeTransferFrom(tokenOwner, address(this), tokenId);
        }

        emit TokenListed(tokenOwner, tokenId, price);
    }

    function purchase(uint256 tokenId) public whenNotPaused {
        require(listing[tokenId].listed, "Error: Token ID not listed");
        require(IGSERC721(gsERC721).ownerOf(tokenId) == address(this), "Error: Marketplace does not own this token");

        address buyer = _msgSender();
        address tokenOwner = listing[tokenId].owner;
        address operator = listing[tokenId].operator;

        uint256 currentPrice = listing[tokenId].price;
        uint256 parValue = IGSERC721(gsERC721).getGSValue(tokenId);

        delete listing[tokenId];

        if(tokenOwner == address(this)) {
            require(buyer != operator, "Error: Buyer is the marketplace operator");

            if (currentPrice.sub(parValue) > 0) {
                IERC20(GSD).safeTransferFrom(buyer, operator, currentPrice.sub(parValue));
            } 

            IERC20Burnable(GSD).burnFrom(buyer, parValue);

        } else {
            require(buyer != tokenOwner, "Error: Buyer is the token owner");
            IERC20(GSD).safeTransferFrom(buyer, tokenOwner, currentPrice);

        }
        
        IGSERC721(gsERC721).safeTransferFrom(address(this), buyer, tokenId);

        emit TokenPurchased(buyer, tokenId, currentPrice);
    }

    function unlist(uint256 tokenId) external {
        address caller = _msgSender();

        require(listing[tokenId].listed, "Error: Token ID not listed");
        require(caller == listing[tokenId].owner || caller == listing[tokenId].operator, "Error: Caller is not owner or approved");

        IGSERC721(gsERC721).safeTransferFrom(address(this), listing[tokenId].owner, tokenId);

        delete listing[tokenId];

        emit TokenUnlisted(tokenId);
    }

    function mint(string calldata tokenURI, uint256 gsEquivalence) external onlyOwner {
        IGSERC721(gsERC721).mint(address(this), tokenURI, gsEquivalence);
    }

    function burn(uint256 tokenId) external onlyOwner {
        require(!listing[tokenId].listed, "Error: Token listed");
        IGSERC721(gsERC721).burn(tokenId);
    }

    function togglePause() public onlyOwner {
        if (!paused()) _pause();
        else _unpause();
    }

    function setPrice(uint256 _tokenId, uint256 _price) public {
        address caller = _msgSender();

        require(listing[_tokenId].listed, "Error: Token ID not listed");
        require(caller == listing[_tokenId].owner || caller == listing[_tokenId].operator, "Error: Caller is not owner or approved");

        // Primary sale cannot perform at discount value.
        if (listing[_tokenId].owner == address(this)) {
            require(_price >= IGSERC721(gsERC721).getGSValue(_tokenId), "Error: Price below par value");
        }

        listing[_tokenId].price = _price;

        emit TokenPriceChanged(_tokenId, _price);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IDetailedERC20} from "./interfaces/IDetailedERC20.sol";

/// @title GsAuxToken
///
/// @dev This is the contract for the AUX-based utility token.
///
/// Initially, the contract deployer is given both the admin and minter role. This allows them to pre-mine tokens,
/// transfer admin to a timelock contract, and lastly, grant the staking pools the minter role. After this is done,
/// the deployer must revoke their admin role and minter role.
contract GsAuxToken is AccessControl, ERC20 {
  using SafeERC20 for ERC20;

  /// @dev The identifier of the role which maintains other roles.
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

  /// @dev The identifier of the role which allows accounts to mint tokens.
  bytes32 public constant SENTINEL_ROLE = keccak256("SENTINEL");
  
  /// @dev addresses whitelisted for minting new tokens
  mapping (address => bool) public whitelist;
  
  /// @dev addresses blacklisted for minting new tokens
  mapping (address => bool) public blacklist;

  /// @dev addresses paused for minting new tokens
  mapping (address => bool) public paused;

  /// @dev ceiling per address for minting new tokens
  mapping (address => uint256) public ceiling;

  /// @dev already minted amount per address to track the ceiling
  mapping (address => uint256) public hasMinted;

  event Paused(address gsditeAddress, bool isPaused);
  
  constructor() ERC20("GSDAO AUX Token", "gsAux") public {
    _setupRole(ADMIN_ROLE, msg.sender);
    _setupRole(SENTINEL_ROLE, msg.sender);
    _setRoleAdmin(SENTINEL_ROLE,ADMIN_ROLE);
    _setRoleAdmin(ADMIN_ROLE,ADMIN_ROLE);
  }

  function decimals() public view virtual override returns (uint8) {
      return 18;
  }

  /// @dev A modifier which checks if whitelisted for minting.
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender], "GsAux: Gsdite is not whitelisted");
    _;
  }

  /// @dev Mints tokens to a recipient.
  ///
  /// This function reverts if the caller does not have the minter role.
  ///
  /// @param _recipient the account to mint tokens to.
  /// @param _amount    the amount of tokens to mint.
  function mint(address _recipient, uint256 _amount) external onlyWhitelisted {
    require(!blacklist[msg.sender], "GsAux: Gsdite is blacklisted");
    uint256 _total = _amount.add(hasMinted[msg.sender]);
    require(_total <= ceiling[msg.sender],"GsAux: Gsdite's ceiling was breached");
    require(!paused[msg.sender], "GsAux: user is currently paused.");
    hasMinted[msg.sender] = hasMinted[msg.sender].add(_amount);
    _mint(_recipient, _amount);
  }
  
  /// This function reverts if the caller does not have the admin role.
  ///
  /// @param _toWhitelist the account to mint tokens to.
  /// @param _state the whitelist state.

  function setWhitelist(address _toWhitelist, bool _state) external onlyAdmin {
    whitelist[_toWhitelist] = _state;
  }

  /// This function reverts if the caller does not have the admin role.
  ///
  /// @param _newSentinel the account to set as sentinel.

  function setSentinel(address _newSentinel) external onlyAdmin {
    _setupRole(SENTINEL_ROLE, _newSentinel);
  }

  /// This function reverts if the caller does not have the admin role.
  ///
  /// @param _toBlacklist the account to mint tokens to.
  function setBlacklist(address _toBlacklist) external onlySentinel {
    blacklist[_toBlacklist] = true;
  }

  /// This function reverts if the caller does not have the admin role.
  function pauseGsdite(address _toPause, bool _state) external onlySentinel {
    paused[_toPause] = _state;
    Paused(_toPause, _state);
  }

  /// This function reverts if the caller does not have the admin role.
  ///
  /// @param _toSetCeiling the account set the ceiling off.
  /// @param _ceiling the max amount of tokens the account is allowed to mint.
  function setCeiling(address _toSetCeiling, uint256 _ceiling) external onlyAdmin {
    ceiling[_toSetCeiling] = _ceiling;
  }

   /// @dev A modifier which checks that the caller has the admin role.
  modifier onlyAdmin() {
    require(hasRole(ADMIN_ROLE, msg.sender), "Error: Only admin");
    _;
  }

  /// @dev A modifier which checks that the caller has the sentinel role.
  modifier onlySentinel() {
    require(hasRole(SENTINEL_ROLE, msg.sender), "Error: Only sentinel");
    _;
  }
  /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
    /**
     * @dev lowers hasminted from the caller's allocation
     *
     */
    function lowerHasMinted( uint256 amount) public onlyWhitelisted {
        if (hasMinted[msg.sender] >= amount) {
          hasMinted[msg.sender] = hasMinted[msg.sender].sub(amount);
        } else {
          hasMinted[msg.sender] = 0;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title ERC20Mock
///
/// @dev A mock of an ERC20 token which lets anyone burn and mint tokens.
contract ERC20Mock is ERC20 {

  constructor(string memory _name, string memory _symbol, uint8 _decimals) public ERC20(_name, _symbol) {
    _setupDecimals(_decimals);
  }

  function mint(address _recipient, uint256 _amount) external {
    _mint(_recipient, _amount);
  }

  function burn(address _account, uint256 _amount) external {
    _burn(_account, _amount);
  }
}

pragma solidity >=0.6.0;

//import {IDetailedERC20} from "../interfaces/IDetailedERC20.sol"; 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UsdcToken is ERC20 {
    constructor(uint256 _initialSupply)
       public ERC20("UsdcToken", "UsdcToken")
    {
        _mint(_msgSender(), _initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
    /*
    function mint(uint256 value) public {
        _mint(_msgSender(), value);
    }
    */
    function mint(address receiver, uint256 value) public {
        _mint(receiver, value);
    }
}

contract AuxToken is ERC20 {
    constructor(uint256 _initialSupply)
       public ERC20("AuxToken", "AuxToken")
    {
        _mint(_msgSender(), _initialSupply);
    }

    function mint(uint256 value) public {
        _mint(_msgSender(), value);
    }

    function mintTo(address receiver, uint256 value) public {
        _mint(receiver, value);
    }
}

contract GsdTokenMock is ERC20 {
    constructor(uint256 _initialSupply)
       public ERC20("GsdToken", "GsdToken")
    {
        _mint(_msgSender(), _initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function mint(uint256 value) public {
        _mint(_msgSender(), value);
    }

    function mintTo(address receiver, uint256 value) public {
        _mint(receiver, value);
    }
}

// SPDX-License-Identifier: GPL-3.0
// Note: internal audit passed.
pragma solidity =0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IDetailedERC20} from "./interfaces/IDetailedERC20.sol";

import "./ERC20LockRegistry.sol";
import 'hardhat/console.sol';

/*
 * Requirements:
 * Max supply = 33000 GSD
 * 18 decimals.
 * Only owner allowed to mint.
*/

contract GSDToken is ERC20LockRegistry, Ownable {

    using SafeMath for uint256;

    uint256 public maxSupply;
    uint256 public mintedSupply;

    mapping(address => bool) public allowedBurners;

    modifier onlyOwnerOrAllowed() {
        require(msg.sender == owner() || allowedBurners[msg.sender] == true, "Error: Not allowed to burn");
        _;
    }

    constructor(uint256 _maxSupply) ERC20LockRegistry("Mock GSD Token", "MGSD") public { // Mainnet: "Gold Standard DAO Token", "GSD"
        require(_maxSupply > 0, "Error: Null amount");

        maxSupply = _maxSupply;
    }

    function setLocker(address account, bool status) external onlyOwner {
        _setLocker(account, status);
    }

    function mint(address account, uint256 mintAmount) external onlyOwner {
        require(mintedSupply.add(mintAmount) <= maxSupply, "ERC20Capped: cap exceeded");

        mintedSupply = mintedSupply.add(mintAmount);
        _mint(account, mintAmount);
    }

    function burn(uint256 amount) external onlyOwnerOrAllowed {
        _burn(_msgSender(), amount);
    } 

    function burnFrom(address account, uint256 amount) external onlyOwnerOrAllowed {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    function toggleAllowedBurner(address account) external onlyOwner {
        allowedBurners[account] = !allowedBurners[account];
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20LockRegistry is ERC20 {

    using SafeMath for uint256;

    mapping(address => bool) private _lockers;

    mapping(address => uint256) private _lockedBalances;

    event LockerStatus(address account, bool status);
    event BalanceLocked(address account, uint256 amount);
    event BalanceUnlocked(address account, uint256 amount);

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) public {}
    
    function lockBalance(address account, uint256 amount) external {
        require(_lockers[_msgSender()], "Error: Caller is not a locker");
        require(amount <= availableBalanceOf(account), "Error: Not enough available balance");

        _lockedBalances[account] = _lockedBalances[account].add(amount);

        emit BalanceLocked(account, amount);
    }

    function unlockBalance(address account, uint256 amount) external {
        require(_lockers[_msgSender()], "Error: Caller is not a locker");

        _lockedBalances[account] = _lockedBalances[account].sub(amount);

        emit BalanceUnlocked(account, amount);
    }

    function _setLocker(address account, bool status) internal {
        require(_lockers[account] != status, "Error: Locker status already set as desired");

        _lockers[account] = status;
        emit LockerStatus(account, status);
    }

    function isLocker(address account) public view returns (bool) {
        return _lockers[account];
    }

    function lockedBalanceOf(address account) public view virtual returns (uint256) {
        return _lockedBalances[account];
    }

    function availableBalanceOf(address account) public view virtual returns (uint256) {
        return super.balanceOf(account).sub(_lockedBalances[account]);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if(from != address(0)) {
            require(amount <= availableBalanceOf(from), "Error: Not enough available balance");
        }
    }
}

// SPDX-License-Identifier: MIT
// Note: internal audit passed.
// Post audit comments: add premia on staked NFTs. Add locked feature in order not to transfer GSD tokens.

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import {IDetailedERC20} from "./interfaces/IDetailedERC20.sol"; 
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./interfaces/IERC20LockRegistry.sol";
import "./GSERC721.sol";

import "hardhat/console.sol";

contract GsdStaking is ReentrancyGuard {

    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IDetailedERC20;
    using SafeMath for uint256;
    using Address for address;

    uint256 constant public BASE_INDEX = 1e18;
    uint256 constant public UNIT_RETURNS = 1e18;
    uint256 constant public NFT_PREMIUM = 115; // 15% above par value.

    uint256 public current_index;
    //uint256 public interestTokenBalance;
    
    address public immutable governor;

    address public nftcontract;
    bool public nftSet;

    address public immutable baseToken;
    address public immutable interestToken;

    uint256 public aggregateTVL;
    uint256 public pendingDistribution;

    struct Position {
        uint256 depositGSD;
        uint256 depositNFTValue;
        uint256 TVL;
        uint256 lastIndex;
        uint256 claimableAux;
    }

    mapping(address => Position) public stakers;
    mapping(address => EnumerableSet.UintSet) internal nftStaked;

    event AuxDeposited(uint256 amount);
    event AuxClaimed(address indexed holder, uint256 amount);
    event NewStakingPosition(address indexed depositor, uint256 gsdAmount, uint256[] tokenIds);
    event GsdUnstaked(address indexed depositor, uint256 amount);
    event NFTUnstaked(address indexed depositor, uint256[] tokenIds);
    event IndexUpdated(uint256 newValue);
    event nftContractAdded(address nft);

    constructor(address _governor, address _baseToken, address _interestToken) public {
        require(_governor != address(0), "Error: Cannot be the null address");
        require(_baseToken != address(0), "Error: Cannot be the null address");
        require(_interestToken != address(0), "Error: Cannot be the null address");
        
        current_index = 1e18;

        governor = _governor;
        baseToken = _baseToken;
        interestToken = _interestToken;
    }

    modifier noContractAllowed() {
        require(
            !address(msg.sender).isContract() && msg.sender == tx.origin,
            "Sorry we do not accept contracts!"
        );
        _;
    }

    function addNftContract(address _nftcontract) external {
        require(msg.sender == governor, "Error: Caller is not the governor"); // Maybe we can remove this.
        require(!nftSet, "Error: NFT has already been set");
        require(_nftcontract != address(0), "Error: Cannot be the null address");

        nftcontract = _nftcontract;

        nftSet = true;

        emit nftContractAdded(_nftcontract);
    }

    function deposit(uint256 _amount) external {
        //require(msg.sender == governor, "Error: Caller is not the governor"); // Maybe we can remove this.

        if(aggregateTVL == 0) {
            pendingDistribution = pendingDistribution.add(_amount);

        } else if (pendingDistribution > 0) {
            uint256 totalToDistribute = _amount.add(pendingDistribution);
            updateIndex(totalToDistribute);
            pendingDistribution = 0;

        } else {
            updateIndex(_amount);
        }

        IDetailedERC20(interestToken).safeTransferFrom(msg.sender, address(this), _amount);

        emit AuxDeposited(_amount);
    }

    function stake(uint256 _amount, uint256[] memory tokenIds) external nonReentrant noContractAllowed {
        address depositor = msg.sender;

        (uint256 tvl, uint256 index, uint256 claims) = updateClaimableInterest(depositor);
        uint256 depoGSD = stakers[depositor].depositGSD;
        uint256 depoNFT = stakers[depositor].depositNFTValue;

        if (_amount > 0) {
            depoGSD = depoGSD.add(_amount);
            tvl = tvl.add(_amount);

            aggregateTVL = aggregateTVL.add(_amount);

            //IDetailedERC20(baseToken).safeTransferFrom(depositor, address(this), _amount);
            IERC20LockRegistry(baseToken).lockBalance(depositor, _amount);
        }

        if (nftSet && tokenIds.length > 0) {
            for (uint i = 0; i < tokenIds.length; i++) {
                bool check = nftStaked[depositor].add(tokenIds[i]);
                require(check, "Error: Check reverted");

                uint256 _gsdValue = (GSERC721(nftcontract).getGSValue(tokenIds[i]).mul(NFT_PREMIUM)).div(100);

                depoNFT = depoNFT.add(_gsdValue);
                tvl = tvl.add(_gsdValue);

                aggregateTVL = aggregateTVL.add(_gsdValue);
                                                                                                                                             
                GSERC721(nftcontract).safeTransferFrom(depositor, address(this), tokenIds[i]);
            }
        }
        stakers[depositor] = Position(depoGSD, depoNFT, tvl, index, claims);

        emit NewStakingPosition(depositor, _amount, tokenIds);
    }

    function claim() external nonReentrant noContractAllowed {
        address depositor = msg.sender;

        (, uint256 index, uint256 claims) = updateClaimableInterest(depositor);
        require(claims > 0, "Error: Null BUSD claims");

        stakers[depositor].lastIndex = index;
        stakers[depositor].claimableAux = 0;

        IDetailedERC20(interestToken).safeTransfer(depositor, claims);

        emit AuxClaimed(depositor, claims);
    }

    function unstake(uint256 _amount, uint256[] memory tokenIds, bool _claimAndUnstake) external nonReentrant noContractAllowed {
        address depositor = msg.sender;

        (uint256 tvl, uint256 index, uint256 claims) = updateClaimableInterest(depositor);
        require(tvl > 0, "Error: Null staked balance");

        uint256 depoGSD = stakers[depositor].depositGSD;
        uint256 depoNFT = stakers[depositor].depositNFTValue;

        if (_amount > 0) {
            require(_amount <= depoGSD, "Error: Cannot withdraw more GSD than deposited");

            depoGSD = depoGSD.sub(_amount);
            tvl = tvl.sub(_amount);

            aggregateTVL = aggregateTVL.sub(_amount);

            //IDetailedERC20(baseToken).safeTransfer(depositor, _amount);
            IERC20LockRegistry(baseToken).unlockBalance(depositor, _amount);

            emit GsdUnstaked(depositor, _amount);
        }

        if (nftSet && tokenIds.length > 0) {

            for (uint256 i = 0; i < tokenIds.length; i++) {
                require(nftStaked[depositor].contains(tokenIds[i]), "Error: Depositor does not own tokenId");

                uint256 _gsdValue = (GSERC721(nftcontract).getGSValue(tokenIds[i]).mul(NFT_PREMIUM)).div(100);

                depoNFT = depoNFT.sub(_gsdValue);
                tvl = tvl.sub(_gsdValue);

                aggregateTVL = aggregateTVL.sub(_gsdValue);

                bool check = nftStaked[depositor].remove(tokenIds[i]);
                require(check, "Error: Check reverted");

                GSERC721(nftcontract).safeTransferFrom(address(this), depositor, tokenIds[i]);
            }

            emit NFTUnstaked(depositor, tokenIds);
        }

        if (tvl == 0) {
            // Claiming is compulsory.
            delete stakers[depositor];
            IDetailedERC20(interestToken).safeTransfer(depositor, claims);

            emit AuxClaimed(depositor, claims);

        } else if (_claimAndUnstake == true) {
            stakers[depositor] = Position(depoGSD, depoNFT, tvl, index, 0);            
            IDetailedERC20(interestToken).safeTransfer(depositor, claims);

            emit AuxClaimed(depositor, claims);

        } else {
           stakers[depositor] = Position(depoGSD, depoNFT, tvl, index, claims);

        }
    }

    function updateIndex(uint256 _newDeposit) internal {
        uint256 unitary_returns = _newDeposit.mul(UNIT_RETURNS).div(aggregateTVL);
        //console.log("Unitary returns: ", unitary_returns);
        current_index = current_index.add(unitary_returns);

        emit IndexUpdated(current_index); 
    }

    function updateClaimableInterest(address depositor) internal view returns (uint256, uint256, uint256) {
        uint256 _depositAmount = stakers[depositor].TVL;
        uint256 _lastIndex = stakers[depositor].lastIndex;
        uint256 _claimableAmount = stakers[depositor].claimableAux;

        if (current_index > _lastIndex) {
            uint256 deltaIndex = current_index.sub(_lastIndex);
            uint256 addClaims = _depositAmount.mul(deltaIndex).div(UNIT_RETURNS);

            _claimableAmount = _claimableAmount.add(addClaims);
            _lastIndex = current_index;
        }

        return (_depositAmount, _lastIndex, _claimableAmount);
    }

    function getAccruedInterest(address depositor) public view returns (uint256) {
        (,, uint256 accruedAux) = updateClaimableInterest(depositor);

        return accruedAux;
    }

    function getAmountOfStakedTokens(address depositor) external view returns (uint256) {
        require(nftSet, "Error: NFT has not yet been set");

        return nftStaked[depositor].length();
    }

    function getStakedTokenAt(address depositor, uint256 index) external view returns (uint256) {
        require(nftSet, "Error: NFT has not yet been set");
        require(nftStaked[depositor].length() > index, "Error: Empty index");
        
        return nftStaked[depositor].at(index);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.6.0;

import "./IDetailedERC20.sol";

interface IERC20LockRegistry is IDetailedERC20 {
    function lockBalance(address account, uint256 amount) external;

    function unlockBalance(address account, uint256 amount) external;

    function lockedBalanceOf(address account) external returns (uint256);

    function availableBalanceOf(address account) external returns (uint256);

    function isLocker(address account) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
// Note: internal audit passed.
pragma solidity =0.6.12;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract GSERC721 is ERC721, Ownable {
    
    uint256 private _currentId;
    address public marketplace;

    mapping(uint256 => uint256) private gsdEquivalence;

    event MarketplaceSet(address _address);

    modifier onlyMarketplace() {
        require(msg.sender == marketplace, "Caller is not the marketplace");
        _;
    }

    constructor() ERC721("GS DAO Token Collection", "GSNFT") public {
    }

    function mint(address to, string calldata tokenURI, uint256 gsEquivalence) external onlyMarketplace {
        require(gsEquivalence != 0, "Error: Amount cannot be null");

        gsdEquivalence[_currentId] = gsEquivalence;
        _safeMint(to, _currentId);
        _setTokenURI(_currentId, tokenURI);

        _currentId += 1;
    }

    function burn(uint256 tokenId) external onlyMarketplace {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    function getGSValue(uint256 tokenId) public view returns(uint256) {
        return gsdEquivalence[tokenId];
    }

    function setMarketplace(address _marketplace) external onlyOwner {
        require(_marketplace != address(0), "Error: Cannot be the null address");
        marketplace = _marketplace;

        emit MarketplaceSet(_marketplace);
    }
}

/**
 *Submitted for verification at Etherscan.io on 2017-12-12
*/

// Copyright (C) 2015, 2016, 2017 Dapphub

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.6.12;

import "hardhat/console.sol";

contract WETH9 {
    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    constructor() public payable {
        deposit();
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {

            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}