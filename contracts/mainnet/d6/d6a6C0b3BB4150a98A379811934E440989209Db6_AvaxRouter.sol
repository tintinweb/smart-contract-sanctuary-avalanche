// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import "../interfaces/IARC20.sol";

interface IRouter {
    function depositWithExpiry(
        address,
        address,
        uint256,
        string calldata,
        uint256
    ) external;
}

// THORChain_Router is managed by THORChain Vaults
contract AvaxRouter {
    struct Coin {
        address asset;
        uint256 amount;
    }

    // Vault allowance for each asset
    mapping(address => mapping(address => uint256)) private _vaultAllowance;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    // Emitted for all deposits, the memo distinguishes for swap, add, remove, donate etc
    event Deposit(
        address indexed to,
        address indexed asset,
        uint256 amount,
        string memo
    );

    // Emitted for all outgoing transfers, the vault dictates who sent it, memo used to track.
    event TransferOut(
        address indexed vault,
        address indexed to,
        address asset,
        uint256 amount,
        string memo
    );

    // Emitted for all outgoing transferAndCalls, the vault dictates who sent it, memo used to track.
    event TransferOutAndCall(
        address indexed vault,
        address target,
        uint256 amount,
        address finalAsset,
        address to,
        uint256 amountOutMin,
        string memo
    );

    // Changes the spend allowance between vaults
    event TransferAllowance(
        address indexed oldVault,
        address indexed newVault,
        address asset,
        uint256 amount,
        string memo
    );

    // Specifically used to batch send the entire vault assets
    event VaultTransfer(
        address indexed oldVault,
        address indexed newVault,
        Coin[] coins,
        string memo
    );

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @notice Calls deposit with an experation
     * @param vault address - vault address for router
     * @param asset address - ARC20 asset or zero address for AVAX
     * @param amount uint - amount to deposit
     * @param memo string - tx memo
     * @param expiration string - timestamp for expiration
     */
    function depositWithExpiry(
        address payable vault,
        address asset,
        uint256 amount,
        string memory memo,
        uint256 expiration
    ) external payable {
        require(block.timestamp < expiration, "THORChain_Router: expired");
        deposit(vault, asset, amount, memo);
    }

    /**
     * @notice Deposit an asset with a memo. Avax is forwarded, ARC-20 stays in ROUTER
     * @param vault address - vault address for router
     * @param asset address - ARC20 asset or zero address for AVAX
     * @param amount uint - amount to deposit
     * @param memo string - transaction memo
     */
    function deposit(
        address payable vault,
        address asset,
        uint256 amount,
        string memory memo
    ) public payable nonReentrant {
        uint256 safeAmount;
        if (asset == address(0)) {
            safeAmount = msg.value;
            bool success = vault.send(safeAmount);
            require(success, "Send Failed");
        } else {
            require(msg.value == 0, "unexpected avax"); // protect user from accidentally locking up AVAX

            safeAmount = safeTransferFrom(asset, amount); // Transfer asset
            _vaultAllowance[vault][asset] += safeAmount; // Credit to chosen vault
        }
        emit Deposit(vault, asset, safeAmount, memo);
    }

    /**
     * @notice Use for "moving" assets between vaults (asgard<>ygg), as well "churning" to a new Asgard
     * @param router address - current vault address for router
     * @param newVault address - new vault address for router
     * @param asset address - ARC20 asset or zero address for AVAX
     * @param amount uint - allowance amount to transfer
     * @param memo string - transaction memo
     */
    function transferAllowance(
        address router,
        address newVault,
        address asset,
        uint256 amount,
        string memory memo
    ) external nonReentrant {
        if (router == address(this)) {
            _adjustAllowances(newVault, asset, amount);
            emit TransferAllowance(msg.sender, newVault, asset, amount, memo);
        } else {
            _routerDeposit(router, newVault, asset, amount, memo);
        }
    }

    /**
     * @notice All vault calls to transfer any asset to any recipient go through here.
     * @dev Note: Contract recipients of AVAX are only given 2300 Gas to complete execution.
     * @param to address - current vault address for router
     * @param asset address - ARC20 asset or zero address for AVAX
     * @param amount uint - allowance amount to transfer
     * @param memo string - transaction memo
     */
    function transferOut(
        address payable to,
        address asset,
        uint256 amount,
        string memory memo
    ) public payable nonReentrant {
        uint256 safeAmount;
        if (asset == address(0)) {
            safeAmount = msg.value;
            bool success = to.send(safeAmount); // Send AVAX.
            if (!success) {
                payable(address(msg.sender)).transfer(safeAmount); // For failure, bounce back to Yggdrasil & continue.
            }
        } else {
            _vaultAllowance[msg.sender][asset] -= amount; // Reduce allowance
            (bool success, bytes memory data) = asset.call(
                abi.encodeWithSignature("transfer(address,uint256)", to, amount)
            );
            require(success && (data.length == 0 || abi.decode(data, (bool))), "transfer out failed");
            safeAmount = amount;
        }
        emit TransferOut(msg.sender, to, asset, safeAmount, memo);
    }

    /**
     * @notice Any vault calls to transferAndCall on a target contract that conforms with "swapOut(address,address,uint256)"
     * @dev Example Memo: "~1b3:AVAX.0xFinalToken:0xTo:
     * @dev Target is fuzzy-matched to the last three digits of whitelisted aggregators
     * @dev FinalToken, To, amountOutMin come from originating memo
     * @param target address - current vault address for router
     * @param finalToken address - ARC20 asset or zero address for AVAX
     * @param to address - address to send swapped assets to
     * @param amountOutMin uint - allowance amount to transfer
     * @param memo string - transaction memo of type "OUT:HASH"
     */
    function transferOutAndCall(
        address payable target,
        address finalToken,
        address to,
        uint256 amountOutMin,
        string memory memo
    ) public payable nonReentrant {
        uint256 _safeAmount = msg.value;
        (bool arc20Success, ) = target.call{value: _safeAmount}(
            abi.encodeWithSignature(
                "swapOut(address,address,uint256)",
                finalToken,
                to,
                amountOutMin
            )
        );
        if (!arc20Success) {
            bool avaxSuccess = payable(to).send(_safeAmount); // If can't swap, just send the recipient the AVAX
            if (!avaxSuccess) {
                payable(address(msg.sender)).transfer(_safeAmount); // For failure, bounce back to Yggdrasil & continue.
            }
        }
        emit TransferOutAndCall(
            msg.sender,
            target,
            _safeAmount,
            finalToken,
            to,
            amountOutMin,
            memo
        );
    }

    /**
     * @notice  A vault can call to "return" all assets to an asgard, including AVAX.
     * @param router address - current vault address for router
     * @param asgard address - current address for asgard
     * @param coins Coin[] - ARC20/AVAX in vault - { asset: address, amount: uint }
     * @param memo string - transaction memo
     */
    function returnVaultAssets(
        address router,
        address payable asgard,
        Coin[] memory coins,
        string memory memo
    ) external payable nonReentrant {
        if (router == address(this)) {
            for (uint256 i = 0; i < coins.length; i++) {
                _adjustAllowances(asgard, coins[i].asset, coins[i].amount);
            }
            emit VaultTransfer(msg.sender, asgard, coins, memo); // Does not include AVAX.
        } else {
            for (uint256 i = 0; i < coins.length; i++) {
                _routerDeposit(
                    router,
                    asgard,
                    coins[i].asset,
                    coins[i].amount,
                    memo
                );
            }
        }
        bool success = asgard.send(msg.value);
        require(success, "return vault assets failed");
    }

    /**
     * @notice Checks allowance of vault.
     * @param vault address - current vault address for router
     * @param token address - token to check allowance
     */
    function vaultAllowance(address vault, address token)
        public
        view
        returns (uint256 amount)
    {
        return _vaultAllowance[vault][token];
    }

    /**
     * @notice Safe transferFrom in case asset charges transfer fees
     * @param _asset address - asset that will transferFrom
     * @param _amount uint - amount to transfer
     */
    function safeTransferFrom(address _asset, uint256 _amount)
        internal
        returns (uint256 amount)
    {
        uint256 _startBal = IARC20(_asset).balanceOf(address(this));
        (bool success, bytes memory data) = _asset.call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                address(this),
                _amount
            )
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Failed To TransferFrom"
        );
        return (IARC20(_asset).balanceOf(address(this)) - _startBal);
    }

    /**
     * @notice Decrements and Increments Allowances between two vaults
     * @param _newVault address - new vault to receive the allowance
     * @param _asset address - asset that has the allowance
     * @param _amount uint - amount of allowance to transfer
     */
    function _adjustAllowances(
        address _newVault,
        address _asset,
        uint256 _amount
    ) internal {
        _vaultAllowance[msg.sender][_asset] -= _amount;
        _vaultAllowance[_newVault][_asset] += _amount;
    }

    /**
     * @notice Adjusts allowance and forwards funds to new router, credits allowance to desired vault
     * @param _router address - current router address
     * @param _vault address - vault to deposit to
     * @param _asset address - ARC20 asset or zero address for AVAX
     * @param _amount uint - amount to transfer
     */
    function _routerDeposit(
        address _router,
        address _vault,
        address _asset,
        uint256 _amount,
        string memory _memo
    ) internal {
        _vaultAllowance[msg.sender][_asset] -= _amount;
        (bool success, ) = _asset.call(
            abi.encodeWithSignature(
                "approve(address,uint256)",
                _router,
                _amount
            )
        ); // Approve to transfer
        require(success, "router deposit failed");
        IRouter(_router).depositWithExpiry(
            _vault,
            _asset,
            _amount,
            _memo,
            type(uint256).max
        ); // Transfer by depositing
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IARC20 is IERC20 {}

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