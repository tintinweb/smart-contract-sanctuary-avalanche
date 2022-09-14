// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "IERC20.sol";
import "Ownable.sol";
import "IVault.sol";

/// @title Referral Vault Wrapper
/// @author RoboVault
/// @notice A vault wrapper that's intend for use in conjunction with The Graph protocol to coordinate
/// a vault referral program.
contract ReferralVaultWrapper is Ownable {
    /// @param _treasury treasury address
    constructor(address _treasury) public {
        treasury = _treasury;
    }

    /*///////////////////////////////////////////////////////////////
                            TREASURY STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Default address for users with no referrer
    address public treasury;

    /// @notice Emitted when the treasury is changed
    event TreasuryUpdated(address oldTreasury, address newTreasury);

    /// @notice Update the treasury address.
    /// @param _newTreasury new treasury address
    function setTreasury(address _newTreasury) external onlyOwner {
        address old = treasury;
        treasury = _newTreasury;
        emit TreasuryUpdated(old, treasury);
    }

    /*///////////////////////////////////////////////////////////////
                            APPROVED VAULT STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice mapping of vaults the owner of the contract has approved. Given users will
    /// be approving this contract to spend tokens, only approved vaults tokens are allowed
    /// for use.
    mapping(address => bool) public approvedVaults;

    /// @notice Emits when a vault is permitted or revoked
    event VaultStatusChanged(address vault, bool allowed);

    /// @notice Approves a vault to be used with this wrapper
    /// @param _vault address to the vualt
    function approveVault(address _vault) external onlyOwner {
        approvedVaults[_vault] = true;
        emit VaultStatusChanged(_vault, true);
    }

    /// @notice Revoke permission for a vault
    /// @param _vault address to the vualt
    function revokeVault(address _vault) external onlyOwner {
        approvedVaults[_vault] = false;
        emit VaultStatusChanged(_vault, false);
    }

    /*///////////////////////////////////////////////////////////////
                            REFERRER STORAGE
    //////////////////////////////////////////////////////////////*/
    /// @notice assigned referrers for each user. This is set once on the first deposit
    mapping(address => address) public referrals;

    /// @notice Emits when a referrer is set
    event ReferrerSet(address account, address referrer);

    /// @notice Emits when a referrer is changed. Only owner can change the referrer
    event ReferrerChanged(
        address account,
        address oldReferrer,
        address newReferrer
    );

    /// @notice Overwrites the referrer for a given address
    /// @param _account account address owner is overwriting
    /// @param _newReferrer the new referrer
    function overrideReferrer(address _account, address _newReferrer)
        external
        onlyOwner
    {
        _overrideReferrer(_account, _newReferrer);
    }

    /// @notice Removes the referrer for _account by setting the referrer to treasury
    /// @param _account account address owner is overwriting
    function removeReferrer(address _account) external onlyOwner {
        _overrideReferrer(_account, treasury);
    }

    /// @notice Internal overrideReferrer()
    /// @param _account account address owner is overwriting
    /// @param _newReferrer the new referrer
    function _overrideReferrer(address _account, address _newReferrer)
        internal
    {
        emit ReferrerChanged(_account, referrals[_account], _newReferrer);
        referrals[_account] = _newReferrer;
    }

    /*///////////////////////////////////////////////////////////////
                           VAULT WRAPPER
    //////////////////////////////////////////////////////////////*/

    /// @notice deposit wrapper. Deposits on behalf of a user and sets the referrer
    /// @param _amount amount of vault.token()'s to be deposited on behalf of msg.sender
    /// @param _referrer Referrer address. Zero address will default to treasury address. The user cannot refer themselves.
    /// @param _vault Vault to deposit user funds into
    function deposit(
        uint256 _amount,
        address _referrer,
        address _vault
    ) external returns (uint256) {
        require(_referrer != msg.sender); /// @dev: self_referral
        require(approvedVaults[_vault]); /// @dev: unsupported_vault
        if (_referrer == address(0)) _referrer = treasury;
        address recipient = msg.sender;
        IERC20(IVault(_vault).token()).transferFrom(
            recipient,
            address(this),
            _amount
        );
        IERC20(IVault(_vault).token()).approve(_vault, _amount);
        if (referrals[recipient] == address(0)) {
            referrals[recipient] = (_referrer == address(0))
                ? treasury
                : _referrer;
            emit ReferrerSet(recipient, referrals[recipient]);
        }
        return IVault(_vault).deposit(_amount, recipient);
    }
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

pragma solidity ^0.6.0;

import "Context.sol";
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

// SPDX-License-Identifier: AGPL-3.0
// Feel free to change the license, but this is what we use

// Feel free to change this version of Solidity. We support >=0.6.0 <0.7.0;
pragma solidity 0.6.12;

import "IERC20.sol";

interface IVault is IERC20 {
    /// @notice deposits amount in tokens into vault.
    function deposit(uint256 amount, address recipient)
        external
        returns (uint256);

    /// @notice withdraw amount in shares from the vault.
    function withdraw(uint256 maxShares) external returns (uint256);

    /// @notice returns the underlying of the vault.
    function token() external view returns (address);
}