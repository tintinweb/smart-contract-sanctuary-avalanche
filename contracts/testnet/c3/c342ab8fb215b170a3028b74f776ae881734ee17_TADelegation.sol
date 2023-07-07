// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

import {ITADelegation} from "./interfaces/ITADelegation.sol";
import {TADelegationGetters} from "./TADelegationGetters.sol";
import {TAHelpers} from "ta-common/TAHelpers.sol";
import {RAArrayHelper} from "src/library/arrays/RAArrayHelper.sol";
import {U256ArrayHelper} from "src/library/arrays/U256ArrayHelper.sol";
import {
    FixedPointType,
    FixedPointTypeHelper,
    Uint256WrapperHelper,
    FP_ZERO,
    FP_ONE
} from "src/library/FixedPointArithmetic.sol";
import {RelayerAddress, DelegatorAddress, TokenAddress} from "ta-common/TATypes.sol";
import {RelayerStateManager} from "ta-common/RelayerStateManager.sol";
import {NATIVE_TOKEN} from "ta-common/TAConstants.sol";

/// @title TADelegation
/// @dev Module for delegating tokens to relayers.
/// BICO holders can delegate their tokens to a relayer signaling support to the relayer activity.
/// Delegation increases the total effective staked amount of a relayer, which in turn increases the probability
/// of that particular relayer being selected to relay transactions.
/// Premiums and rewards of the relayers are shared with delegators according to the rules established in the economics of the BRN
///
/// The delegators earn rewards for each token in storage.supportedPools.
/// The accounting for each (relayer, token_pool) is done separately.
/// Each (relayer, token_pool) has a separate share price, determined as:
///    share_price{i} = (total_delegation_in_bico_to_relayer + unclaimed_rewards{i}) / total_shares_minted{i} for total_shares_minted{i} != 0
///                     1 for total_shares_minted{i} == 0
/// for the ith token in storage.supportedPools. Notice that total_delegation_in_bico_to_relayer is common for all supported tokens.
/// When a delegator delegates to a relayer, it receives shares for all tokens in storage.supportedPools, for that relayer.
contract TADelegation is TADelegationGetters, TAHelpers, ITADelegation {
    using FixedPointTypeHelper for FixedPointType;
    using Uint256WrapperHelper for uint256;
    using RAArrayHelper for RelayerAddress[];
    using U256ArrayHelper for uint256[];
    using SafeERC20 for IERC20;
    using RelayerStateManager for RelayerStateManager.RelayerState;

    /// @dev Mints delegation pool shares at the current share price for that relayer's pool
    /// @param _relayerAddress The relayer address to delegate to
    /// @param _delegatorAddress The delegator address
    /// @param _delegatedAmount The amount of bond tokens (bico) to delegate
    /// @param _pool The token for which shares are being minted
    function _mintPoolShares(
        RelayerAddress _relayerAddress,
        DelegatorAddress _delegatorAddress,
        uint256 _delegatedAmount,
        TokenAddress _pool
    ) internal {
        TADStorage storage ds = getTADStorage();

        FixedPointType sharePrice_ = _delegationSharePrice(_relayerAddress, _pool, 0);
        FixedPointType sharesMinted = (_delegatedAmount.fp() / sharePrice_);

        ds.shares[_relayerAddress][_delegatorAddress][_pool] =
            ds.shares[_relayerAddress][_delegatorAddress][_pool] + sharesMinted;
        ds.totalShares[_relayerAddress][_pool] = ds.totalShares[_relayerAddress][_pool] + sharesMinted;

        emit SharesMinted(_relayerAddress, _delegatorAddress, _pool, _delegatedAmount, sharesMinted, sharePrice_);
    }

    /// @dev Mints delegation pool shares at the current share price in each supported pool for the delegator
    /// @param _relayerAddress The relayer address to delegate to
    /// @param _delegator The delegator address
    /// @param _amount The amount of bond tokens (bico) to delegate
    function _mintAllPoolShares(RelayerAddress _relayerAddress, DelegatorAddress _delegator, uint256 _amount)
        internal
    {
        TADStorage storage ds = getTADStorage();
        uint256 length = ds.supportedPools.length;
        if (length == 0) {
            revert NoSupportedGasTokens();
        }

        for (uint256 i; i != length;) {
            _mintPoolShares(_relayerAddress, _delegator, _amount, ds.supportedPools[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Delegator are entitled to share of the protocol rewards generated for the relayer.
    ///      This function calcualtes the protocol rewards generated for the relayer since the last time it was calcualted,
    ///      splits the rewards b/w the relayer and the delegators based on the relayer's premium sharing configuration
    /// @param _relayer The relayer address for which the accounting is being updated
    function _updateRelayerProtocolRewards(RelayerAddress _relayer) internal {
        // Non-active relayer do not generate protocol rewards
        if (!_isActiveRelayer(_relayer)) {
            return;
        }

        uint256 updatedTotalUnpaidProtocolRewards = _getLatestTotalUnpaidProtocolRewardsAndUpdateUpdatedTimestamp();
        (uint256 relayerRewards, uint256 delegatorRewards, FixedPointType sharesToBurn) =
            _getPendingProtocolRewardsData(_relayer, updatedTotalUnpaidProtocolRewards);

        // Process delegator rewards
        RMStorage storage rs = getRMStorage();
        RelayerInfo storage relayerInfo = rs.relayerInfo[_relayer];

        if (delegatorRewards > 0) {
            _addDelegatorRewards(_relayer, TokenAddress.wrap(address(rs.bondToken)), delegatorRewards);
        }

        // Store the relayer's rewards in the relayer's state to claim later
        if (relayerRewards > 0) {
            relayerInfo.unpaidProtocolRewards += relayerRewards;
            emit RelayerProtocolRewardsGenerated(_relayer, relayerRewards);
        }

        // Update global accounting
        rs.totalUnpaidProtocolRewards = updatedTotalUnpaidProtocolRewards - relayerRewards - delegatorRewards;
        rs.totalProtocolRewardShares = rs.totalProtocolRewardShares - sharesToBurn;
        relayerInfo.rewardShares = relayerInfo.rewardShares - sharesToBurn;

        emit RelayerProtocolSharesBurnt(_relayer, sharesToBurn);
    }

    /// @inheritdoc ITADelegation
    function delegate(RelayerStateManager.RelayerState calldata _latestState, uint256 _relayerIndex, uint256 _amount)
        external
        override
        noSelfCall
    {
        if (_relayerIndex >= _latestState.relayers.length) {
            revert InvalidRelayerIndex();
        }

        _verifyExternalStateForRelayerStateUpdation(_latestState);

        RelayerAddress relayerAddress = _latestState.relayers[_relayerIndex];
        _updateRelayerProtocolRewards(relayerAddress);

        getRMStorage().bondToken.safeTransferFrom(msg.sender, address(this), _amount);
        TADStorage storage ds = getTADStorage();

        // Mint Shares for all supported pools
        DelegatorAddress delegatorAddress = DelegatorAddress.wrap(msg.sender);
        _mintAllPoolShares(relayerAddress, delegatorAddress, _amount);

        // Update global counters
        ds.delegation[relayerAddress][delegatorAddress] += _amount;
        ds.totalDelegation[relayerAddress] += _amount;
        emit DelegationAdded(relayerAddress, delegatorAddress, _amount);

        // Schedule the CDF update
        uint256[] memory newCdf = _latestState.increaseWeight(_relayerIndex, _amount);
        _cd_updateLatestRelayerState(_latestState.relayers, newCdf);
    }

    struct AmountOwed {
        TokenAddress token;
        uint256 amount;
    }

    /// @dev Calculate and return the rewards earned by the delegator for the given relayer and pool, including the original delegation amount
    /// @param _relayerAddress The relayer address
    /// @param _pool The token for which rewards are being calculated
    /// @param _delegatorAddress The delegator address
    /// @param _bondToken The bond token address
    /// @param _delegation The amount of bond tokens (bico) delegated
    /// @return The amount of rewards earned by the delegator. If _pool==_bondToken, include the original delegation amount
    function _processRewards(
        RelayerAddress _relayerAddress,
        TokenAddress _pool,
        DelegatorAddress _delegatorAddress,
        TokenAddress _bondToken,
        uint256 _delegation
    ) internal returns (AmountOwed memory) {
        TADStorage storage ds = getTADStorage();

        uint256 rewardsEarned_ = _delegationRewardsEarned(_relayerAddress, _pool, _delegatorAddress);

        if (rewardsEarned_ != 0) {
            ds.unclaimedRewards[_relayerAddress][_pool] -= rewardsEarned_;
        }

        // Update global counters
        ds.totalShares[_relayerAddress][_pool] =
            ds.totalShares[_relayerAddress][_pool] - ds.shares[_relayerAddress][_delegatorAddress][_pool];
        ds.shares[_relayerAddress][_delegatorAddress][_pool] = FP_ZERO;

        return AmountOwed({token: _pool, amount: _pool == _bondToken ? rewardsEarned_ + _delegation : rewardsEarned_});
    }

    /// @inheritdoc ITADelegation
    function undelegate(
        RelayerStateManager.RelayerState calldata _latestState,
        RelayerAddress _relayerAddress,
        uint256 _relayerIndex
    ) external override noSelfCall {
        _verifyExternalStateForRelayerStateUpdation(_latestState);

        TADStorage storage ds = getTADStorage();

        _updateRelayerProtocolRewards(_relayerAddress);

        uint256 delegation_ = ds.delegation[_relayerAddress][DelegatorAddress.wrap(msg.sender)];
        TokenAddress bondToken = TokenAddress.wrap(address(getRMStorage().bondToken));

        // Burn shares for each pool and calculate rewards
        uint256 length = ds.supportedPools.length;
        AmountOwed[] memory amountOwed = new AmountOwed[](length);
        for (uint256 i; i != length;) {
            amountOwed[i] = _processRewards(
                _relayerAddress, ds.supportedPools[i], DelegatorAddress.wrap(msg.sender), bondToken, delegation_
            );
            unchecked {
                ++i;
            }
        }

        // Update delegation state
        ds.totalDelegation[_relayerAddress] -= delegation_;
        delete ds.delegation[_relayerAddress][DelegatorAddress.wrap(msg.sender)];
        emit DelegationRemoved(_relayerAddress, DelegatorAddress.wrap(msg.sender), delegation_);

        // Store the rewards and the original stake to be withdrawn after the delay
        DelegationWithdrawal storage withdrawal =
            ds.delegationWithdrawal[_relayerAddress][DelegatorAddress.wrap(msg.sender)];
        withdrawal.minWithdrawalTimestamp = block.timestamp + ds.delegationWithdrawDelayInSec;
        for (uint256 i; i != length;) {
            AmountOwed memory t = amountOwed[i];
            if (t.amount > 0) {
                withdrawal.amounts[t.token] += t.amount;
                emit DelegationWithdrawalCreated(
                    _relayerAddress,
                    DelegatorAddress.wrap(msg.sender),
                    t.token,
                    t.amount,
                    withdrawal.minWithdrawalTimestamp
                );
            }
            unchecked {
                ++i;
            }
        }

        // Update the CDF if and only if the relayer is still registered
        // The delegator should be allowed to undelegate even if the relayer has been removed
        if (_isActiveRelayer(_relayerAddress)) {
            // Verify the relayer index
            if (_latestState.relayers[_relayerIndex] != _relayerAddress) {
                revert InvalidRelayerIndex();
            }

            uint256[] memory newCdf = _latestState.decreaseWeight(_relayerIndex, delegation_);
            _cd_updateLatestRelayerState(_latestState.relayers, newCdf);
        }
    }

    /// @dev The price of for the given relayer and pool
    /// @param _relayerAddress The relayer address
    /// @param _tokenAddress The token (pool) address
    /// @param _extraUnclaimedRewards Rewards to considered in the share price calculation which are not stored in the contract (yet)
    function _delegationSharePrice(
        RelayerAddress _relayerAddress,
        TokenAddress _tokenAddress,
        uint256 _extraUnclaimedRewards
    ) internal view returns (FixedPointType) {
        TADStorage storage ds = getTADStorage();
        FixedPointType totalShares_ = ds.totalShares[_relayerAddress][_tokenAddress];

        if (totalShares_ == FP_ZERO) {
            return FP_ONE;
        }

        return (
            ds.totalDelegation[_relayerAddress] + ds.unclaimedRewards[_relayerAddress][_tokenAddress]
                + _extraUnclaimedRewards
        ).fp() / totalShares_;
    }

    /// @dev Calculate the rewards earned by the delegator for the given relayer and pool
    /// @param _relayerAddress The relayer address
    /// @param _tokenAddress The token (pool) address
    /// @param _delegatorAddress The delegator address
    function _delegationRewardsEarned(
        RelayerAddress _relayerAddress,
        TokenAddress _tokenAddress,
        DelegatorAddress _delegatorAddress
    ) internal view returns (uint256) {
        TADStorage storage ds = getTADStorage();

        FixedPointType currentValue = ds.shares[_relayerAddress][_delegatorAddress][_tokenAddress]
            * _delegationSharePrice(_relayerAddress, _tokenAddress, 0);
        FixedPointType delegation_ = ds.delegation[_relayerAddress][_delegatorAddress].fp();

        if (currentValue >= delegation_) {
            return (currentValue - delegation_).u256();
        }
        return 0;
    }

    /// @inheritdoc ITADelegation
    function claimableDelegationRewards(
        RelayerAddress _relayerAddress,
        TokenAddress _tokenAddress,
        DelegatorAddress _delegatorAddress
    ) external view noSelfCall returns (uint256) {
        TADStorage storage ds = getTADStorage();

        uint256 protocolDelegationRewards;

        if (TokenAddress.unwrap(_tokenAddress) == address(getRMStorage().bondToken)) {
            uint256 updatedTotalUnpaidProtocolRewards = _getLatestTotalUnpaidProtocolRewards();

            (, protocolDelegationRewards,) =
                _getPendingProtocolRewardsData(_relayerAddress, updatedTotalUnpaidProtocolRewards);
        }

        FixedPointType currentValue = ds.shares[_relayerAddress][_delegatorAddress][_tokenAddress]
            * _delegationSharePrice(_relayerAddress, _tokenAddress, protocolDelegationRewards);
        FixedPointType delegation_ = ds.delegation[_relayerAddress][_delegatorAddress].fp();

        if (currentValue >= delegation_) {
            return (currentValue - delegation_).u256();
        }
        return 0;
    }

    /// @inheritdoc ITADelegation
    function withdrawDelegation(RelayerAddress _relayerAddress) external noSelfCall {
        TokenAddress[] storage supportedPools = getTADStorage().supportedPools;
        DelegationWithdrawal storage withdrawal =
            getTADStorage().delegationWithdrawal[_relayerAddress][DelegatorAddress.wrap(msg.sender)];

        if (withdrawal.minWithdrawalTimestamp > block.timestamp) {
            revert WithdrawalNotReady(withdrawal.minWithdrawalTimestamp);
        }

        uint256 length = supportedPools.length;
        for (uint256 i; i != length;) {
            TokenAddress tokenAddress = supportedPools[i];

            uint256 amount = withdrawal.amounts[tokenAddress];
            delete withdrawal.amounts[tokenAddress];

            _transfer(tokenAddress, msg.sender, amount);

            emit RewardSent(_relayerAddress, DelegatorAddress.wrap(msg.sender), tokenAddress, amount);

            unchecked {
                ++i;
            }
        }

        delete getTADStorage().delegationWithdrawal[_relayerAddress][DelegatorAddress.wrap(msg.sender)];
    }

    /// @inheritdoc ITADelegation
    function addDelegationRewards(RelayerAddress _relayerAddress, uint256 _tokenIndex, uint256 _amount)
        external
        payable
        override
        noSelfCall
    {
        TADStorage storage ds = getTADStorage();

        if (_tokenIndex >= ds.supportedPools.length) {
            revert InvalidTokenIndex();
        }
        TokenAddress tokenAddress = ds.supportedPools[_tokenIndex];

        // Accept the tokens
        if (tokenAddress != NATIVE_TOKEN) {
            IERC20(TokenAddress.unwrap(tokenAddress)).safeTransferFrom(msg.sender, address(this), _amount);
        } else if (msg.value != _amount) {
            revert NativeAmountMismatch();
        }

        // Add to unclaimed rewards
        _addDelegatorRewards(_relayerAddress, tokenAddress, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.19;

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.19;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        if (nonceAfter != nonceBefore + 1) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ITADelegationEventsErrors} from "./ITADelegationEventsErrors.sol";
import {ITADelegationGetters} from "./ITADelegationGetters.sol";
import {RelayerAddress, DelegatorAddress, TokenAddress} from "ta-common/TATypes.sol";
import {RelayerStateManager} from "ta-common/RelayerStateManager.sol";

/// @title ITADelegation
/// @dev Interface for the delegation module.
interface ITADelegation is ITADelegationEventsErrors, ITADelegationGetters {
    /// @notice Delegate tokens to a relayer.
    /// @param _latestState The latest relayer state, used to calculate the new state post delegation.
    /// @param _relayerIndex The index of the relayer to delegate to in the latest relayer state.
    /// @param _amount The amount of tokens to delegate.
    function delegate(RelayerStateManager.RelayerState calldata _latestState, uint256 _relayerIndex, uint256 _amount)
        external;

    /// @notice Undelegate tokens from a relayer and calculates rewards. The rewards are not transferred, and must be
    ///         claimed by calling withdrawDelegation after a delay.
    /// @param _latestState The latest relayer state, used to calculate the new state post undelegation.
    /// @param _relayerAddress The address of the relayer to undelegate from.
    /// @param _relayerIndex The index of the relayer to undelegate from in the latest relayer state. If the relayer is unregistered
    ///                      or exiting, this can be set to 0.
    function undelegate(
        RelayerStateManager.RelayerState calldata _latestState,
        RelayerAddress _relayerAddress,
        uint256 _relayerIndex
    ) external;

    /// @notice Allows the withdrawal of a delegation after a delay.
    /// @param _relayerAddress The address of the relayer to which funds were originally delegated to.
    function withdrawDelegation(RelayerAddress _relayerAddress) external;

    /// @notice Calculate the amount of rewards claimable by a delegator.
    /// @param _relayerAddress The address of the relayer to which the delegator has delegated to.
    /// @param _tokenAddress The address of the token to calculate rewards for.
    /// @param _delegatorAddress The address of the delegator to calculate rewards for.
    function claimableDelegationRewards(
        RelayerAddress _relayerAddress,
        TokenAddress _tokenAddress,
        DelegatorAddress _delegatorAddress
    ) external view returns (uint256);

    /// @notice Allows an arbitrary called to supply additional rewards to a relayer's delegators.
    /// @param _relayerAddress The address of the relayer to add rewards to.
    /// @param _tokenIndex The index of the token (in supportedTokens array) to add rewards.
    /// @param _amount The amount of tokens to add as rewards.
    function addDelegationRewards(RelayerAddress _relayerAddress, uint256 _tokenIndex, uint256 _amount)
        external
        payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {RelayerAddress, DelegatorAddress, TokenAddress} from "ta-common/TATypes.sol";
import {FixedPointType} from "src/library/FixedPointArithmetic.sol";
import {ITADelegationGetters} from "./interfaces/ITADelegationGetters.sol";
import {TADelegationStorage} from "./TADelegationStorage.sol";
import {Guards} from "src/utils/Guards.sol";

/// @title TADelegationGetters
abstract contract TADelegationGetters is TADelegationStorage, ITADelegationGetters, Guards {
    function totalDelegation(RelayerAddress _relayerAddress) external view override noSelfCall returns (uint256) {
        return getTADStorage().totalDelegation[_relayerAddress];
    }

    function delegation(RelayerAddress _relayerAddress, DelegatorAddress _delegatorAddress)
        external
        view
        override
        noSelfCall
        returns (uint256)
    {
        return getTADStorage().delegation[_relayerAddress][_delegatorAddress];
    }

    function shares(RelayerAddress _relayerAddress, DelegatorAddress _delegatorAddress, TokenAddress _tokenAddress)
        external
        view
        override
        noSelfCall
        returns (FixedPointType)
    {
        return getTADStorage().shares[_relayerAddress][_delegatorAddress][_tokenAddress];
    }

    function totalShares(RelayerAddress _relayerAddress, TokenAddress _tokenAddress)
        external
        view
        override
        noSelfCall
        returns (FixedPointType)
    {
        return getTADStorage().totalShares[_relayerAddress][_tokenAddress];
    }

    function unclaimedDelegationRewards(RelayerAddress _relayerAddress, TokenAddress _tokenAddress)
        external
        view
        override
        noSelfCall
        returns (uint256)
    {
        return getTADStorage().unclaimedRewards[_relayerAddress][_tokenAddress];
    }

    function supportedPools() external view override noSelfCall returns (TokenAddress[] memory) {
        return getTADStorage().supportedPools;
    }

    function minimumDelegationAmount() external view override noSelfCall returns (uint256) {
        return getTADStorage().minimumDelegationAmount;
    }

    function delegationWithdrawal(RelayerAddress _relayerAddress, DelegatorAddress _delegatorAddress)
        external
        view
        override
        noSelfCall
        returns (DelegationWithdrawalResult memory)
    {
        DelegationWithdrawal storage withdrawal =
            getTADStorage().delegationWithdrawal[_relayerAddress][_delegatorAddress];
        DelegationWithdrawalEntry[] memory withdrawals = new DelegationWithdrawalEntry[](
            getTADStorage().supportedPools.length
        );
        for (uint256 i = 0; i < getTADStorage().supportedPools.length; i++) {
            withdrawals[i] = DelegationWithdrawalEntry({
                tokenAddress: getTADStorage().supportedPools[i],
                amount: withdrawal.amounts[getTADStorage().supportedPools[i]]
            });
        }
        return DelegationWithdrawalResult({
            minWithdrawalTimestamp: withdrawal.minWithdrawalTimestamp,
            withdrawals: withdrawals
        });
    }

    function delegationWithdrawDelayInSec() external view override noSelfCall returns (uint256) {
        return getTADStorage().delegationWithdrawDelayInSec;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";

import {ITAHelpers} from "./interfaces/ITAHelpers.sol";
import {TARelayerManagementStorage} from "ta-relayer-management/TARelayerManagementStorage.sol";
import {TADelegationStorage} from "ta-delegation/TADelegationStorage.sol";
import {
    Uint256WrapperHelper,
    FixedPointTypeHelper,
    FixedPointType,
    FP_ZERO,
    FP_ONE
} from "src/library/FixedPointArithmetic.sol";
import {VersionManager} from "src/library/VersionManager.sol";
import {RelayerAddress, TokenAddress, RelayerStatus} from "./TATypes.sol";
import {BOND_TOKEN_DECIMAL_MULTIPLIER, NATIVE_TOKEN, PERCENTAGE_MULTIPLIER} from "./TAConstants.sol";
import {RelayerStateManager} from "./RelayerStateManager.sol";
import {RAArrayHelper} from "src/library/arrays/RAArrayHelper.sol";
import {U256ArrayHelper} from "src/library/arrays/U256ArrayHelper.sol";

/// @title TAHelpers
/// @dev Common contract inherited by all core modules of the Transaction Allocator. Provides various helper functions.
abstract contract TAHelpers is TARelayerManagementStorage, TADelegationStorage, ITAHelpers {
    using SafeERC20 for IERC20;
    using Address for address payable;
    using Uint256WrapperHelper for uint256;
    using FixedPointTypeHelper for FixedPointType;
    using VersionManager for VersionManager.VersionManagerState;
    using RelayerStateManager for RelayerStateManager.RelayerState;
    using RAArrayHelper for RelayerAddress[];
    using U256ArrayHelper for uint256[];

    ////////////////////////////// Verification Helpers //////////////////////////////
    modifier onlyActiveRelayer(RelayerAddress _relayer) {
        if (!_isActiveRelayer(_relayer)) {
            revert RelayerIsNotActive(_relayer);
        }
        _;
    }

    /// @dev Returns true if the relayer is active in the pending/latest state.
    ///      A relayer which has requested unregistration or jailing could be active in the current state, but not in the pending/latest state.
    /// @param _relayer The relayer address
    /// @return true if the relayer is active
    function _isActiveRelayer(RelayerAddress _relayer) internal view returns (bool) {
        return getRMStorage().relayerInfo[_relayer].status == RelayerStatus.Active;
    }

    /// @dev Verifies that the passed relayer state corresponds to the latest/pending state.
    ///      Updates to the Relayer State must take into account already queued updates, hence the verification against the latest state.
    ///      Reverts if the state verification fails.
    /// @param _state The relayer state to be verified
    function _verifyExternalStateForRelayerStateUpdation(RelayerStateManager.RelayerState calldata _state)
        internal
        view
    {
        if (!getRMStorage().relayerStateVersionManager.verifyHashAgainstLatestState(_state.hash())) {
            revert InvalidLatestRelayerState();
        }
    }

    /// @dev Verifies that the passed relayer state corresponds to the currently active state.
    ///      Reverts if the state verification fails.
    /// @param _state The relayer state to be verified
    /// @param _blockNumber The block number at which the state is to be verified
    function _verifyExternalStateForTransactionAllocation(
        RelayerStateManager.RelayerState calldata _state,
        uint256 _blockNumber
    ) internal view {
        // The unit of time for the relayer state is the window index.
        uint256 windowIndex = _windowIndex(_blockNumber);

        if (!getRMStorage().relayerStateVersionManager.verifyHashAgainstActiveState(_state.hash(), windowIndex)) {
            revert InvalidActiveRelayerState();
        }
    }

    ////////////////////////////// Relayer Selection //////////////////////////////

    /// @dev A non-decreasing numerical identifier for a given window. A window is a contigous set of blocks of length blocksPerWindow.
    /// @param _blockNumber The block number for which the window index is to be calculated
    /// @return The index of window in which _blockNumber falls
    function _windowIndex(uint256 _blockNumber) internal view returns (uint256) {
        return _blockNumber / getRMStorage().blocksPerWindow;
    }

    /// @dev Given a block number, returns the window index a future window in which any relayer state updates should be applied.
    /// @param _blockNumber The block number for which the next update window index is to be calculated
    /// @return The index of the window in which the relayer state updates should be applied
    function _nextWindowForUpdate(uint256 _blockNumber) internal view returns (uint256) {
        return _windowIndex(_blockNumber) + getRMStorage().relayerStateUpdateDelayInWindows;
    }

    ////////////////////////////// Relayer State //////////////////////////////

    /// @dev Sets the latest relayer state, but does not schedule it for activation.
    /// @param _relayers The list of relayers in the new state
    /// @param _cdf The cumulative distribution function of the stake + delegation of relayers in the new state
    function _cd_updateLatestRelayerState(RelayerAddress[] calldata _relayers, uint256[] memory _cdf) internal {
        bytes32 newRelayerStateHash = RelayerStateManager.hash(_cdf, _relayers);
        getRMStorage().relayerStateVersionManager.setLatestState(newRelayerStateHash, _windowIndex(block.number));
        emit NewRelayerState(newRelayerStateHash, _relayers, _cdf);
    }

    /// @dev Sets the latest relayer state, but does not schedule it for activation.
    /// @param _relayers The list of relayers in the new state
    /// @param _cdf The cumulative distribution function of the stake + delegation of relayers in the new state
    function _m_updateLatestRelayerState(RelayerAddress[] memory _relayers, uint256[] memory _cdf) internal {
        bytes32 newRelayerStateHash = RelayerStateManager.hash(_cdf.m_hash(), _relayers.m_hash());
        getRMStorage().relayerStateVersionManager.setLatestState(newRelayerStateHash, _windowIndex(block.number));
        emit NewRelayerState(newRelayerStateHash, _relayers, _cdf);
    }

    ////////////////////////////// Delegation ////////////////////////

    /// @dev Records the rewards to be distributed to delegators of the given relayer
    /// @param _relayer The relayer whose delegators are to be rewarded
    /// @param _token The token in which the rewards are to be distributed
    /// @param _amount The amount of rewards to be distributed
    function _addDelegatorRewards(RelayerAddress _relayer, TokenAddress _token, uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }
        getTADStorage().unclaimedRewards[_relayer][_token] += _amount;
        emit DelegatorRewardsAdded(_relayer, _token, _amount);
    }

    ////////////////////////// Constant Rate Rewards //////////////////////////

    /// @dev The BRN generates "protocol rewards" in the form of bond tokens (BICO) at a rate R.
    ///      The base reward factor (B) is a constant that is set by the BRN.
    ///      An increment (b) is defined as the Minimum amount of stake required by relayers.
    ///      Assuming S is the total stake, the reward rate is given by:
    ///         Base Reward Per Increment/s (I) = B * b / sqrt(S)
    ///         Total Reward Rate/s (R) = I * S / b = B * sqrt(S)
    ///
    /// @return The current reward generation rate R in bond Token (BICO) wei/sec
    function _protocolRewardRate() internal view returns (uint256) {
        RMStorage storage rs = getRMStorage();
        FixedPointType rate =
            rs.totalStake.fp().div(BOND_TOKEN_DECIMAL_MULTIPLIER).sqrt().mul(rs.baseRewardRatePerMinimumStakePerSec);
        return rate.u256();
    }

    /// @dev Returns the total amount of protocol rewards generated by the BRN since the last update.
    /// @return updatedTotalUnpaidProtocolRewards
    function _getLatestTotalUnpaidProtocolRewards() internal view returns (uint256 updatedTotalUnpaidProtocolRewards) {
        RMStorage storage rs = getRMStorage();

        if (block.timestamp == rs.lastUnpaidRewardUpdatedTimestamp) {
            return rs.totalUnpaidProtocolRewards;
        }

        return rs.totalUnpaidProtocolRewards
            + _protocolRewardRate() * (block.timestamp - rs.lastUnpaidRewardUpdatedTimestamp);
    }

    /// @dev Returns the total amount of protocol rewards generated by the BRN since the last update and updates the last update timestamp in storage.
    ///      The unpaidRewards are not updated in storage yet, it is expected that the calling function would perform the update,
    ///      after performing any other necessary operations and deductions from this amount.
    /// @return updatedTotalUnpaidProtocolRewards
    function _getLatestTotalUnpaidProtocolRewardsAndUpdateUpdatedTimestamp()
        internal
        returns (uint256 updatedTotalUnpaidProtocolRewards)
    {
        uint256 unpaidRewards = _getLatestTotalUnpaidProtocolRewards();
        getRMStorage().lastUnpaidRewardUpdatedTimestamp = block.timestamp;
        return unpaidRewards;
    }

    /// @dev Protocol rewards are distributed to the relayers through a shares mechanism.
    ///      During registration, a relayer is assigned a number of shares proportional to the amount of stake they have,
    ///      based on a non-decreasing share price.
    ///      The share price increases as more protocol rewards are generated.
    /// @param _unpaidRewards The total amount of protocol rewards that are generated but not distributed to the relayers.
    /// @return The share price of the protocol rewards.
    function _protocolRewardRelayerSharePrice(uint256 _unpaidRewards) internal view returns (FixedPointType) {
        RMStorage storage rs = getRMStorage();

        if (rs.totalProtocolRewardShares == FP_ZERO) {
            return FP_ONE;
        }
        return (rs.totalStake + _unpaidRewards).fp() / rs.totalProtocolRewardShares;
    }

    /// @dev Returns the amount of unclaimed protocol rewards earned by the given relayer.
    /// @param _relayer The relayer whose unclaimed protocol rewards are to be returned.
    /// @param _unpaidRewards The total amount of protocol rewards that are generated but not distributed to the relayers.
    /// @return The amount of unclaimed protocol rewards earned by the given relayer.
    function _protocolRewardsEarnedByRelayer(RelayerAddress _relayer, uint256 _unpaidRewards)
        internal
        view
        returns (uint256)
    {
        RMStorage storage rs = getRMStorage();
        uint256 totalValue =
            (rs.relayerInfo[_relayer].rewardShares * _protocolRewardRelayerSharePrice(_unpaidRewards)).u256();

        unchecked {
            uint256 rewards =
                totalValue >= rs.relayerInfo[_relayer].stake ? totalValue - rs.relayerInfo[_relayer].stake : 0;
            return rewards;
        }
    }

    /// @dev Utility function to calculate the protocol reward split between the relayer and the delegators.
    /// @param _totalRewards The total amount of protocol rewards earned by the relayer to be split.
    /// @param _delegatorRewardSharePercentage The percentage of the total rewards to be given to the delegators.
    /// @return The amount of rewards to be given to the relayer
    /// @return The amount of rewards to be given to the delegators
    function _calculateProtocolRewardSplit(uint256 _totalRewards, uint256 _delegatorRewardSharePercentage)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 delegatorRewards = (_totalRewards * _delegatorRewardSharePercentage) / (100 * PERCENTAGE_MULTIPLIER);
        return (_totalRewards - delegatorRewards, delegatorRewards);
    }

    /// @dev Calculates the amount of unclaimed protocol rewards earned by the given relayer, then calculates the split b/w the
    ///      relayer and the delegators, and finally calculates the amount of shares to be burned to claim these rewards.
    /// @param _relayer The relayer whose unclaimed protocol rewards are to be returned.
    /// @param _unpaidRewards The total amount of protocol rewards that are generated but not distributed to the relayers.
    /// @return relayerRewards The amount of rewards to be given to the relayer
    /// @return delegatorRewards The amount of rewards to be given to the delegators
    /// @return sharesToBurn The amount of shares to be burned to claim these rewards.
    function _getPendingProtocolRewardsData(RelayerAddress _relayer, uint256 _unpaidRewards)
        internal
        view
        returns (uint256 relayerRewards, uint256 delegatorRewards, FixedPointType sharesToBurn)
    {
        uint256 rewards = _protocolRewardsEarnedByRelayer(_relayer, _unpaidRewards);
        if (rewards == 0) {
            return (0, 0, FP_ZERO);
        }

        sharesToBurn = rewards.fp() / _protocolRewardRelayerSharePrice(_unpaidRewards);

        (relayerRewards, delegatorRewards) =
            _calculateProtocolRewardSplit(rewards, getRMStorage().relayerInfo[_relayer].delegatorPoolPremiumShare);
    }

    ////////////////////////////// Misc //////////////////////////////

    /// @dev Utility function to transfer tokens from TransactionAllocator to the given address.
    /// @param _token The token to transfer.
    /// @param _to The address to transfer the tokens to.
    /// @param _amount The amount of tokens to transfer.
    function _transfer(TokenAddress _token, address _to, uint256 _amount) internal {
        if (_token == NATIVE_TOKEN) {
            payable(_to).sendValue(_amount);
        } else {
            IERC20(TokenAddress.unwrap(_token)).safeTransfer(_to, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {RelayerAddress} from "ta-common/TATypes.sol";

/// @title Relayer Address Array Helper
/// @dev Helper functions for arrays of RelayerAddress
library RAArrayHelper {
    error IndexOutOfBoundsRA(uint256 index, uint256 length);

    /// @dev Copies the array into memory and appends the value
    /// @param _array The array to append to
    /// @param _value The value to append
    /// @return The new array
    function cd_append(RelayerAddress[] calldata _array, RelayerAddress _value)
        internal
        pure
        returns (RelayerAddress[] memory)
    {
        uint256 length = _array.length;
        RelayerAddress[] memory newArray = new RelayerAddress[](
            length + 1
        );

        for (uint256 i; i != length;) {
            newArray[i] = _array[i];
            unchecked {
                ++i;
            }
        }
        newArray[length] = _value;

        return newArray;
    }

    /// @dev Copies the array into memory and removes the value at the index, substituting the last value
    /// @param _array The array to remove from
    /// @param _index The index to remove
    /// @return The new array
    function cd_remove(RelayerAddress[] calldata _array, uint256 _index)
        internal
        pure
        returns (RelayerAddress[] memory)
    {
        uint256 newLength = _array.length - 1;
        if (_index > newLength) {
            revert IndexOutOfBoundsRA(_index, _array.length);
        }

        RelayerAddress[] memory newArray = new RelayerAddress[](newLength);

        for (uint256 i; i != newLength;) {
            if (i != _index) {
                newArray[i] = _array[i];
            } else {
                newArray[i] = _array[newLength];
            }
            unchecked {
                ++i;
            }
        }

        return newArray;
    }

    /// @dev Copies the array into memory and updates the value at the index
    /// @param _array The array to update
    /// @param _index The index to update
    /// @param _value The value to update
    /// @return The new array
    function cd_update(RelayerAddress[] calldata _array, uint256 _index, RelayerAddress _value)
        internal
        pure
        returns (RelayerAddress[] memory)
    {
        if (_index >= _array.length) {
            revert IndexOutOfBoundsRA(_index, _array.length);
        }

        RelayerAddress[] memory newArray = _array;
        newArray[_index] = _value;
        return newArray;
    }

    /// @dev Calculate the hash of the array by packing the values and hashing them through keccak256
    /// @param _array The array to hash
    /// @return The hash of the array
    function cd_hash(RelayerAddress[] calldata _array) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked((_array)));
    }

    /// @dev Calculate the hash of the array by packing the values and hashing them through keccak256
    /// @param _array The array to hash
    /// @return The hash of the array
    function m_hash(RelayerAddress[] memory _array) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked((_array)));
    }

    /// @dev Removes the value at the index, substituting the last value.
    /// @param _array The array to remove from
    /// @param _index The index to remove
    function m_remove(RelayerAddress[] memory _array, uint256 _index) internal pure {
        uint256 newLength = _array.length - 1;

        if (_index > newLength) {
            revert IndexOutOfBoundsRA(_index, _array.length);
        }

        if (_index != newLength) {
            _array[_index] = _array[newLength];
        }

        // Reduce the array size
        assembly {
            mstore(_array, sub(mload(_array), 1))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/// @title uint256 Array Helper
/// @dev Helper functions for arrays of uint256
library U256ArrayHelper {
    error IndexOutOfBoundsU256(uint256 index, uint256 length);

    /// @dev Copies the array into memory and appends the value
    /// @param _array The array to append to
    /// @param _value The value to append
    /// @return The new array
    function cd_append(uint256[] calldata _array, uint256 _value) internal pure returns (uint256[] memory) {
        uint256 length = _array.length;
        uint256[] memory newArray = new uint256[](
            length + 1
        );

        for (uint256 i; i != length;) {
            newArray[i] = _array[i];
            unchecked {
                ++i;
            }
        }
        newArray[length] = _value;

        return newArray;
    }

    /// @dev Copies the array into memory and removes the value at the index, substituting the last value
    /// @param _array The array to remove from
    /// @param _index The index to remove
    /// @return The new array
    function cd_remove(uint256[] calldata _array, uint256 _index) internal pure returns (uint256[] memory) {
        uint256 newLength = _array.length - 1;
        if (_index > newLength) {
            revert IndexOutOfBoundsU256(_index, _array.length);
        }

        uint256[] memory newArray = new uint256[](newLength);

        for (uint256 i; i != newLength;) {
            if (i != _index) {
                newArray[i] = _array[i];
            } else {
                newArray[i] = _array[newLength];
            }
            unchecked {
                ++i;
            }
        }

        return newArray;
    }

    /// @dev Copies the array into memory and updates the value at the index
    /// @param _array The array to update
    /// @param _index The index to update
    /// @param _value The value to update
    /// @return The new array
    function cd_update(uint256[] calldata _array, uint256 _index, uint256 _value)
        internal
        pure
        returns (uint256[] memory)
    {
        if (_index >= _array.length) {
            revert IndexOutOfBoundsU256(_index, _array.length);
        }

        uint256[] memory newArray = _array;
        newArray[_index] = _value;
        return newArray;
    }

    /// @dev Calculate the hash of the array by packing the values and hashing them through keccak256
    /// @param _array The array to hash
    /// @return The hash of the array
    function cd_hash(uint256[] calldata _array) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked((_array)));
    }

    /// @dev Returns the index of the first element in _array greater than or equal to _target
    ///      The array must be sorted
    /// @param _array The array to find in
    /// @param _target The target value
    /// @return The index of the first element greater than or equal to _target
    function cd_lowerBound(uint256[] calldata _array, uint256 _target) internal pure returns (uint256) {
        uint256 low;
        uint256 high = _array.length;
        unchecked {
            while (low < high) {
                uint256 mid = (low + high) / 2;
                if (_array[mid] < _target) {
                    low = mid + 1;
                } else {
                    high = mid;
                }
            }
        }
        return low;
    }

    /// @dev Calculate the hash of the array by packing the values and hashing them through keccak256
    /// @param _array The array to hash
    /// @return The hash of the array
    function m_hash(uint256[] memory _array) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked((_array)));
    }

    /// @dev Removes the value at the index, substituting the last value.
    /// @param _array The array to remove from
    /// @param _index The index to remove
    function m_remove(uint256[] memory _array, uint256 _index) internal pure {
        uint256 newLength = _array.length - 1;

        if (_index > newLength) {
            revert IndexOutOfBoundsU256(_index, _array.length);
        }

        if (_index != newLength) {
            _array[_index] = _array[newLength];
        }

        // Reduce the array size
        assembly {
            mstore(_array, sub(mload(_array), 1))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Math} from "openzeppelin-contracts/utils/math/Math.sol";

using Math for uint256;
using Uint256WrapperHelper for uint256;
using FixedPointTypeHelper for FixedPointType;

uint256 constant PRECISION = 24;
uint256 constant MULTIPLIER = 10 ** PRECISION;

FixedPointType constant FP_ZERO = FixedPointType.wrap(0);
FixedPointType constant FP_ONE = FixedPointType.wrap(MULTIPLIER);

type FixedPointType is uint256;

/// @dev Helpers for converting uint256 to FixedPointType
library Uint256WrapperHelper {
    /// @dev Converts a uint256 to a FixedPointType by multiplying by MULTIPLIER
    /// @param _value The value to convert
    /// @return The converted value
    function fp(uint256 _value) internal pure returns (FixedPointType) {
        return FixedPointType.wrap(_value * MULTIPLIER);
    }
}

/// @dev Helpers for FixedPointType
library FixedPointTypeHelper {
    /// @dev Converts a FixedPointType to a uint256 by dividing by MULTIPLIER
    /// @param _value The value to convert
    /// @return The converted value
    function u256(FixedPointType _value) internal pure returns (uint256) {
        return FixedPointType.unwrap(_value) / MULTIPLIER;
    }

    /// @dev Calculates the square root of a FixedPointType
    /// @param _a The value to calculate the square root of
    /// @return The square root
    function sqrt(FixedPointType _a) internal pure returns (FixedPointType) {
        return FixedPointType.wrap((FixedPointType.unwrap(_a) * MULTIPLIER).sqrt());
    }

    /// @dev Multiplies a FixedPointType by a uint256, does not handle overflows
    /// @param _a Multiplicant
    /// @param _value Multiplier
    /// @return The product in FixedPointType
    function mul(FixedPointType _a, uint256 _value) internal pure returns (FixedPointType) {
        return FixedPointType.wrap(FixedPointType.unwrap(_a) * _value);
    }

    /// @dev Divides a FixedPointType by a uint256
    /// @param _a Dividend
    /// @param _value Divisor
    /// @return The result in FixedPointType
    function div(FixedPointType _a, uint256 _value) internal pure returns (FixedPointType) {
        return FixedPointType.wrap(FixedPointType.unwrap(_a) / _value);
    }
}

// Custom operator implementations for FixedPointType
function fixedPointAdd(FixedPointType _a, FixedPointType _b) pure returns (FixedPointType) {
    return FixedPointType.wrap(FixedPointType.unwrap(_a) + FixedPointType.unwrap(_b));
}

function fixedPointSubtract(FixedPointType _a, FixedPointType _b) pure returns (FixedPointType) {
    return FixedPointType.wrap(FixedPointType.unwrap(_a) - FixedPointType.unwrap(_b));
}

function fixedPointMultiply(FixedPointType _a, FixedPointType _b) pure returns (FixedPointType) {
    return FixedPointType.wrap(Math.mulDiv(FixedPointType.unwrap(_a), FixedPointType.unwrap(_b), MULTIPLIER));
}

function fixedPointDivide(FixedPointType _a, FixedPointType _b) pure returns (FixedPointType) {
    return FixedPointType.wrap(Math.mulDiv(FixedPointType.unwrap(_a), MULTIPLIER, FixedPointType.unwrap(_b)));
}

function fixedPointEquality(FixedPointType _a, FixedPointType _b) pure returns (bool) {
    return FixedPointType.unwrap(_a) == FixedPointType.unwrap(_b);
}

function fixedPointInequality(FixedPointType _a, FixedPointType _b) pure returns (bool) {
    return FixedPointType.unwrap(_a) != FixedPointType.unwrap(_b);
}

function fixedPointGt(FixedPointType _a, FixedPointType _b) pure returns (bool) {
    return FixedPointType.unwrap(_a) > FixedPointType.unwrap(_b);
}

function fixedPointGte(FixedPointType _a, FixedPointType _b) pure returns (bool) {
    return FixedPointType.unwrap(_a) >= FixedPointType.unwrap(_b);
}

function fixedPointLt(FixedPointType _a, FixedPointType _b) pure returns (bool) {
    return FixedPointType.unwrap(_a) < FixedPointType.unwrap(_b);
}

function fixedPointLte(FixedPointType _a, FixedPointType _b) pure returns (bool) {
    return FixedPointType.unwrap(_a) <= FixedPointType.unwrap(_b);
}

using {
    fixedPointAdd as +,
    fixedPointSubtract as -,
    fixedPointMultiply as *,
    fixedPointDivide as /,
    fixedPointEquality as ==,
    fixedPointInequality as !=,
    fixedPointGt as >,
    fixedPointGte as >=,
    fixedPointLt as <,
    fixedPointLte as <=
} for FixedPointType global;

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

//////////////////////////// UDVTS ////////////////////////////

type RelayerAddress is address;

function relayerEquality(RelayerAddress a, RelayerAddress b) pure returns (bool) {
    return RelayerAddress.unwrap(a) == RelayerAddress.unwrap(b);
}

function relayerInequality(RelayerAddress a, RelayerAddress b) pure returns (bool) {
    return RelayerAddress.unwrap(a) != RelayerAddress.unwrap(b);
}

using {relayerEquality as ==, relayerInequality as !=} for RelayerAddress global;

type DelegatorAddress is address;

function delegatorEquality(DelegatorAddress a, DelegatorAddress b) pure returns (bool) {
    return DelegatorAddress.unwrap(a) == DelegatorAddress.unwrap(b);
}

function delegatorInequality(DelegatorAddress a, DelegatorAddress b) pure returns (bool) {
    return DelegatorAddress.unwrap(a) != DelegatorAddress.unwrap(b);
}

using {delegatorEquality as ==, delegatorInequality as !=} for DelegatorAddress global;

type RelayerAccountAddress is address;

function relayerAccountEquality(RelayerAccountAddress a, RelayerAccountAddress b) pure returns (bool) {
    return RelayerAccountAddress.unwrap(a) == RelayerAccountAddress.unwrap(b);
}

function relayerAccountInequality(RelayerAccountAddress a, RelayerAccountAddress b) pure returns (bool) {
    return RelayerAccountAddress.unwrap(a) != RelayerAccountAddress.unwrap(b);
}

using {relayerAccountEquality as ==, relayerAccountInequality as !=} for RelayerAccountAddress global;

type TokenAddress is address;

function tokenEquality(TokenAddress a, TokenAddress b) pure returns (bool) {
    return TokenAddress.unwrap(a) == TokenAddress.unwrap(b);
}

function tokenInequality(TokenAddress a, TokenAddress b) pure returns (bool) {
    return TokenAddress.unwrap(a) != TokenAddress.unwrap(b);
}

using {tokenEquality as ==, tokenInequality as !=} for TokenAddress global;

//////////////////////////// Enums ////////////////////////////

/// @dev Enum for the status of a relayer.
enum RelayerStatus {
    Uninitialized, // The relayer has not registered in the system, or has successfully unregistered and exited.
    Active, // The relayer is active in the system.
    Exiting, // The relayer has called unregister(), and is waiting for the exit period to end to claim it's stake.
    Jailed // The relayer has been jailed by the system and must wait for the jail time to expire before manually re-entering or exiting.
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {RelayerAddress} from "./TATypes.sol";
import {RAArrayHelper} from "src/library/arrays/RAArrayHelper.sol";
import {U256ArrayHelper} from "src/library/arrays/U256ArrayHelper.sol";

/// @title RelayerStateManager
/// @dev Library for managing the state of the relayers.
library RelayerStateManager {
    using RAArrayHelper for RelayerAddress[];
    using U256ArrayHelper for uint256[];

    /// @dev Struct for storing the state of all relayers in the system.
    /// @custom:member cdf The cumulative distribution function of the relayers.
    /// @custom:member relayers The list of relayers.
    struct RelayerState {
        uint256[] cdf;
        RelayerAddress[] relayers;
    }

    /// @dev Appends a new relayer with the given stake to the state.
    /// @param _prev The previous state of the relayers.
    /// @param _relayerAddress The address of the relayer.
    /// @param _stake The stake of the relayer.
    /// @return newState The new state of the relayers.
    function addNewRelayer(RelayerState calldata _prev, RelayerAddress _relayerAddress, uint256 _stake)
        internal
        pure
        returns (RelayerState memory newState)
    {
        newState = RelayerState({
            cdf: _prev.cdf.cd_append(_stake + _prev.cdf[_prev.cdf.length - 1]),
            relayers: _prev.relayers.cd_append(_relayerAddress)
        });
    }

    /// @dev Removes a relayer from the state at the given index
    /// @param _prev The previous state of the relayers.
    /// @param _index The index of the relayer to remove.
    /// @return newState The new state of the relayers.
    function removeRelayer(RelayerState calldata _prev, uint256 _index)
        internal
        pure
        returns (RelayerState memory newState)
    {
        uint256 length = _prev.cdf.length;
        uint256 weightRemoved = _prev.cdf[_index] - (_index == 0 ? 0 : _prev.cdf[_index - 1]);
        uint256 lastWeight = _prev.cdf[length - 1] - (length == 1 ? 0 : _prev.cdf[length - 2]);

        // Copy all the elements except the last one
        uint256[] memory newCdf = new uint256[](length - 1);
        --length;
        for (uint256 i; i != length;) {
            newCdf[i] = _prev.cdf[i];

            unchecked {
                ++i;
            }
        }

        // Update the CDF starting from the index
        if (_index < length) {
            bool elementAtIndexIsIncreased = lastWeight >= weightRemoved;
            uint256 deltaAtIndex = elementAtIndexIsIncreased ? lastWeight - weightRemoved : weightRemoved - lastWeight;

            for (uint256 i = _index; i != length;) {
                if (elementAtIndexIsIncreased) {
                    newCdf[i] += deltaAtIndex;
                } else {
                    newCdf[i] -= deltaAtIndex;
                }

                unchecked {
                    ++i;
                }
            }
        }

        newState = RelayerState({cdf: newCdf, relayers: _prev.relayers.cd_remove(_index)});
    }

    /// @dev Increases the weight of a relayer in the CDF.
    /// @param _prev The previous state of the relayers.
    /// @param _relayerIndex The index of the relayer to update.
    /// @param _value The value to increase the relayer weight by.
    /// @return newCdf The new CDF of the relayers.
    function increaseWeight(RelayerState calldata _prev, uint256 _relayerIndex, uint256 _value)
        internal
        pure
        returns (uint256[] memory newCdf)
    {
        newCdf = _prev.cdf;
        uint256 length = newCdf.length;
        for (uint256 i = _relayerIndex; i != length;) {
            newCdf[i] += _value;
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Decreases the weight of a relayer in the CDF.
    /// @param _prev The previous state of the relayers.
    /// @param _relayerIndex The index of the relayer to update.
    /// @param _value The value to decrease the relayer weight by.
    /// @return newCdf The new CDF of the relayers.
    function decreaseWeight(RelayerState calldata _prev, uint256 _relayerIndex, uint256 _value)
        internal
        pure
        returns (uint256[] memory newCdf)
    {
        newCdf = _prev.cdf;
        uint256 length = newCdf.length;
        for (uint256 i = _relayerIndex; i != length;) {
            newCdf[i] -= _value;
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Given a CDF, calculates an array of individual weights.
    /// @param _cdf The CDF to convert.
    /// @return weights The array of weights.
    function cdfToWeights(uint256[] calldata _cdf) internal pure returns (uint256[] memory weights) {
        uint256 length = _cdf.length;
        weights = new uint256[](length);
        weights[0] = _cdf[0];
        for (uint256 i = 1; i != length;) {
            weights[i] = _cdf[i] - _cdf[i - 1];
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Given an array of weights, calculates the CDF.
    /// @param _weights The array of weights to convert.
    /// @return cdf The CDF.
    function weightsToCdf(uint256[] memory _weights) internal pure returns (uint256[] memory cdf) {
        uint256 length = _weights.length;
        cdf = new uint256[](length);
        uint256 sum;
        for (uint256 i; i != length;) {
            sum += _weights[i];
            cdf[i] = sum;
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Hash function used to generate the hash of the relayer state.
    /// @param _cdfHash The hash of the CDF array
    /// @param _relayerArrayHash The hash of the relayer array
    /// @return The hash of the relayer state
    function hash(bytes32 _cdfHash, bytes32 _relayerArrayHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_cdfHash, _relayerArrayHash));
    }

    /// @dev Hash function used to generate the hash of the relayer state.
    /// @param _state The relayer state
    /// @return The hash of the relayer state
    function hash(RelayerState memory _state) internal pure returns (bytes32) {
        return hash(_state.cdf.m_hash(), _state.relayers.m_hash());
    }

    /// @dev Hash function used to generate the hash of the relayer state. This variant is useful when the
    ///      original list of relayers has not changed
    /// @param _cdf The CDF array
    /// @param _relayers The relayer array
    /// @return The hash of the relayer state
    function hash(uint256[] memory _cdf, RelayerAddress[] calldata _relayers) internal pure returns (bytes32) {
        return hash(_cdf.m_hash(), _relayers.cd_hash());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {TokenAddress} from "./TATypes.sol";

// Controls the precision for specifying percentages. A value of 100 corresponds to precision upto two decimal places, like 12.23%
uint256 constant PERCENTAGE_MULTIPLIER = 100;

// The BICO Token is guaranteed to have 18 decimals
uint256 constant BOND_TOKEN_DECIMAL_MULTIPLIER = 10 ** 18;

// Sentinel value for native token address
TokenAddress constant NATIVE_TOKEN = TokenAddress.wrap(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.19;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.19;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, 0, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with a
     * `customRevert` function as a fallback when `target` reverts.
     *
     * Requirements:
     *
     * - `customRevert` must be a reverting function.
     *
     * _Available since v5.0._
     */
    function functionCall(
        address target,
        bytes memory data,
        function() internal view customRevert
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, customRevert);
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
        return functionCallWithValue(target, data, value, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with a `customRevert` function as a fallback revert reason when `target` reverts.
     *
     * Requirements:
     *
     * - `customRevert` must be a reverting function.
     *
     * _Available since v5.0._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        function() internal view customRevert
    ) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, customRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        function() internal view customRevert
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, customRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        function() internal view customRevert
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, customRevert);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided `customRevert`) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v5.0._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        function() internal view customRevert
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check if target is a contract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                if (target.code.length == 0) {
                    revert AddressEmptyCode(target);
                }
            }
            return returndata;
        } else {
            _revert(returndata, customRevert);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or with a default revert error.
     *
     * _Available since v5.0._
     */
    function verifyCallResult(bool success, bytes memory returndata) internal view returns (bytes memory) {
        return verifyCallResult(success, returndata, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-verifyCallResult-bool-bytes-}[`verifyCallResult`], but with a
     * `customRevert` function as a fallback when `success` is `false`.
     *
     * Requirements:
     *
     * - `customRevert` must be a reverting function.
     *
     * _Available since v5.0._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        function() internal view customRevert
    ) internal view returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, customRevert);
        }
    }

    /**
     * @dev Default reverting function when no `customRevert` is provided in a function call.
     */
    function defaultRevert() internal pure {
        revert FailedInnerCall();
    }

    function _revert(bytes memory returndata, function() internal view customRevert) private view {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            customRevert();
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {RelayerAddress, TokenAddress, DelegatorAddress} from "ta-common/TATypes.sol";
import {FixedPointType} from "src/library/FixedPointArithmetic.sol";

/// @title ITADelegationEventsErrors
interface ITADelegationEventsErrors {
    error NoSupportedGasTokens();
    error InvalidRelayerIndex();
    error InvalidTokenIndex();
    error NativeAmountMismatch();
    error WithdrawalNotReady(uint256 minWithdrawalTimestamp);

    event SharesMinted(
        RelayerAddress indexed relayerAddress,
        DelegatorAddress indexed delegatorAddress,
        TokenAddress indexed pool,
        uint256 delegatedAmount,
        FixedPointType sharesMinted,
        FixedPointType sharePrice
    );
    event DelegationAdded(
        RelayerAddress indexed relayerAddress, DelegatorAddress indexed delegatorAddress, uint256 amount
    );
    event RewardSent(
        RelayerAddress indexed relayerAddress,
        DelegatorAddress indexed delegatorAddress,
        TokenAddress indexed tokenAddress,
        uint256 amount
    );
    event DelegationRemoved(
        RelayerAddress indexed relayerAddress, DelegatorAddress indexed delegatorAddress, uint256 amount
    );
    event RelayerProtocolRewardsGenerated(RelayerAddress indexed relayerAddress, uint256 indexed amount);
    event DelegationWithdrawalCreated(
        RelayerAddress indexed relayerAddress,
        DelegatorAddress indexed delegatorAddress,
        TokenAddress indexed tokenAddress,
        uint256 amount,
        uint256 minWithdrawalTimestamp
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {RelayerAddress, DelegatorAddress, TokenAddress} from "ta-common/TATypes.sol";
import {FixedPointType} from "src/library/FixedPointArithmetic.sol";

/// @title ITADelegationGetters
interface ITADelegationGetters {
    function totalDelegation(RelayerAddress _relayerAddress) external view returns (uint256);

    function delegation(RelayerAddress _relayerAddress, DelegatorAddress _delegatorAddress)
        external
        view
        returns (uint256);

    function shares(RelayerAddress _relayerAddress, DelegatorAddress _delegatorAddress, TokenAddress _tokenAddress)
        external
        view
        returns (FixedPointType);

    function totalShares(RelayerAddress _relayerAddress, TokenAddress _tokenAddress)
        external
        view
        returns (FixedPointType);

    function unclaimedDelegationRewards(RelayerAddress _relayerAddress, TokenAddress _tokenAddress)
        external
        view
        returns (uint256);

    struct DelegationWithdrawalEntry {
        TokenAddress tokenAddress;
        uint256 amount;
    }

    struct DelegationWithdrawalResult {
        uint256 minWithdrawalTimestamp;
        DelegationWithdrawalEntry[] withdrawals;
    }

    function delegationWithdrawal(RelayerAddress _relayerAddress, DelegatorAddress _delegatorAddress)
        external
        view
        returns (DelegationWithdrawalResult memory);

    function supportedPools() external view returns (TokenAddress[] memory);

    function minimumDelegationAmount() external view returns (uint256);

    function delegationWithdrawDelayInSec() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {FixedPointType} from "src/library/FixedPointArithmetic.sol";
import {RelayerAddress, DelegatorAddress, TokenAddress} from "ta-common/TATypes.sol";

/// @title TADelegationStorage
abstract contract TADelegationStorage {
    bytes32 internal constant DELEGATION_STORAGE_SLOT = keccak256("Delegation.storage");

    /// @dev Structure for storing the information of a delegation withdrawal.
    /// @custom:member tokens The tokens to be withdrawn.
    /// @custom:member amounts The corresponding amounts of tokens to be withdrawn.
    /// @custom:member minWithdrawalTimestamp The minimum timestamp after which the withdrawal can be executed.
    struct DelegationWithdrawal {
        uint256 minWithdrawalTimestamp;
        mapping(TokenAddress => uint256) amounts;
    }

    struct TADStorage {
        ////////////////////////// Configuration Parameters //////////////////////////
        uint256 minimumDelegationAmount;
        uint256 delegationWithdrawDelayInSec;
        mapping(RelayerAddress => uint256) totalDelegation;
        TokenAddress[] supportedPools;
        ////////////////////////// Delegation State //////////////////////////
        mapping(RelayerAddress => mapping(DelegatorAddress => uint256)) delegation;
        mapping(RelayerAddress => mapping(DelegatorAddress => mapping(TokenAddress => FixedPointType))) shares;
        mapping(RelayerAddress => mapping(TokenAddress => FixedPointType)) totalShares;
        mapping(RelayerAddress => mapping(TokenAddress => uint256)) unclaimedRewards;
        mapping(RelayerAddress => mapping(DelegatorAddress => DelegationWithdrawal)) delegationWithdrawal;
    }

    /* solhint-disable no-inline-assembly */
    function getTADStorage() internal pure returns (TADStorage storage ms) {
        bytes32 slot = DELEGATION_STORAGE_SLOT;
        assembly {
            ms.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IGuards} from "./interfaces/IGuards.sol";

/// @title Guards
/// @dev Common guard modifiers
abstract contract Guards is IGuards {
    ///  @dev Used by core functions to prevent the execute() from function calling them.
    ///       The execute() function of the Transaction Allocation module accepts arbitrary calldata from the user and delegatecalls to itself,
    ///       which means that the user can call any function of the contract with any arguments and the function will be executed in the context of the contract.
    ///       All core public and external functions MUST use this modifier to prevent the execute() function from calling them.
    ///       This is tested in InternalInvocationTest.sol
    modifier noSelfCall() {
        if (msg.sender == address(this)) {
            revert NoSelfCall();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {RelayerAddress, TokenAddress} from "../TATypes.sol";
import {FixedPointType} from "src/library/FixedPointArithmetic.sol";

/// @title ITAHelpers
interface ITAHelpers {
    error RelayerIsNotActive(RelayerAddress relayer);
    error ParameterLengthMismatch();
    error InvalidLatestRelayerState();
    error InvalidActiveRelayerState();

    event DelegatorRewardsAdded(RelayerAddress indexed _relayer, TokenAddress indexed _token, uint256 indexed _amount);
    event RelayerProtocolSharesBurnt(RelayerAddress indexed relayerAddress, FixedPointType indexed sharesBurnt);
    event NewRelayerState(bytes32 indexed relayerStateHash, RelayerAddress[] relayers, uint256[] cdf);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

import {FixedPointType} from "src/library/FixedPointArithmetic.sol";
import {VersionManager} from "src/library/VersionManager.sol";
import {RelayerAddress, RelayerAccountAddress, RelayerStatus, TokenAddress} from "ta-common/TATypes.sol";

/// @title TARelayerManagementStorage
abstract contract TARelayerManagementStorage {
    bytes32 internal constant RELAYER_MANAGEMENT_STORAGE_SLOT = keccak256("RelayerManagement.storage");

    /// @dev Struct for storing relayer information.
    /// @custom:member stake The amount of stake the relayer has in bond token (BICO).
    /// @custom:member endpoint The rpc endpoint of the relayer.
    /// @custom:member isAccount A mapping of relayer account addresses to whether they are a relayer account.
    ///                          A relayer account can submit transactions on behalf of the relayer.
    /// @custom:member status The status of the relayer.
    /// @custom:member minExitTimestamp If status == Jailed, the minimum timestamp after which the relayer can exit jail.
    ///                                 If status == Exiting, the timestamp after which the relayer can withdraw their stake.
    /// @custom:member delegatorPoolPremiumShare The percentage of the relayer protocol rewards the delegators receive.
    /// @custom:member unpaidProtocolRewards The amount of protocol rewards for the relayer that have been accounted for but not yet claimed.
    /// @custom:member rewardShares The amount of protocol rewards shares that have been minted for the relayer.
    struct RelayerInfo {
        uint256 stake;
        string endpoint;
        mapping(RelayerAccountAddress => bool) isAccount;
        RelayerStatus status;
        uint256 minExitTimestamp;
        uint256 delegatorPoolPremiumShare;
        uint256 unpaidProtocolRewards;
        FixedPointType rewardShares;
    }

    /// @dev The storage struct for the RelayerManagement module.
    struct RMStorage {
        ////////////////////////// Configuration Parameters //////////////////////////
        IERC20 bondToken;
        mapping(RelayerAddress => RelayerInfo) relayerInfo;
        uint256 relayersPerWindow;
        uint256 blocksPerWindow;
        uint256 jailTimeInSec;
        uint256 withdrawDelayInSec;
        uint256 absencePenaltyPercentage;
        uint256 minimumStakeAmount;
        uint256 relayerStateUpdateDelayInWindows;
        uint256 baseRewardRatePerMinimumStakePerSec;
        ////////////////////////// Relayer State Management //////////////////////////
        VersionManager.VersionManagerState relayerStateVersionManager;
        ////////////////////////// Constant Rate Rewards //////////////////////////
        uint256 totalUnpaidProtocolRewards;
        uint256 lastUnpaidRewardUpdatedTimestamp;
        FixedPointType totalProtocolRewardShares;
        ////////////////////////// Global counters for the "latest" state //////////////////////////
        uint256 relayerCount;
        uint256 totalStake;
    }

    /* solhint-disable no-inline-assembly */
    function getRMStorage() internal pure returns (RMStorage storage ms) {
        bytes32 slot = RELAYER_MANAGEMENT_STORAGE_SLOT;
        assembly {
            ms.slot := slot
        }
    }

    /* solhint-enable no-inline-assembly */
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/// @title VersionManager
/// @dev A Data Structure for applying delayed updates to a stored state, the state being a single bytes32 value.
/// The state active at the current point of time is the "active state", while any state that has been set but not yet activated is the "latest state".
/// In the absence of any pending state, the active state is the latest state.
/// The active state is generally used to perform any validations in the current context, while the latest state is used to accumulate changes to the state.
/// Time is assumed to be any non-decreasing value, like block.timestamp.
library VersionManager {
    /// @dev Emitted when a new latest state is set for activation.
    /// @param activationTime The time at which the latest state will become the active state.
    /// @param latestState The latest state that will become the active state.
    event VersionManagerLatestStateSetForActivation(uint256 indexed activationTime, bytes32 indexed latestState);

    /// @dev The internal state of the VersionManager.
    /// @custom:member slot1 The first storage slot of the VersionManager. Stores the state which entered the VersionManager "earlier"
    /// @custom:member slot2 The second storage slot of the VersionManager. Stores the state which entered the VersionManager "later"
    /// @custom:member pendingHashActivationTime The time at which the latest state will become the active state, used to decide which of the two slots is the active state and latest state
    struct VersionManagerState {
        bytes32 slot1;
        bytes32 slot2;
        uint256 pendingHashActivationTime;
    }

    /// @dev Initializes the VersionManager with a given state to be set as the active state.
    function initialize(VersionManagerState storage _v, bytes32 _currentHash) internal {
        _v.slot1 = _currentHash;
        _v.slot2 = _currentHash;
    }

    /// @dev Returns the active state hash.
    /// @param _v Version Manager Internal State
    /// @param _currentTime The time at which the active state is being queried.
    /// @return The active state hash.
    function activeStateHash(VersionManagerState storage _v, uint256 _currentTime) internal view returns (bytes32) {
        if (_v.pendingHashActivationTime == 0) {
            return _v.slot1;
        }

        if (_currentTime < _v.pendingHashActivationTime) {
            return _v.slot1;
        }

        return _v.slot2;
    }

    /// @dev Returns the latest state hash.
    /// @param _v Version Manager Internal State
    /// @return The latest state hash.
    function latestStateHash(VersionManagerState storage _v) internal view returns (bytes32) {
        return _v.slot2 == bytes32(0) ? _v.slot1 : _v.slot2;
    }

    /// @dev Returns true if the given hash matches the active state hash else false.
    /// @param _v Version Manager Internal State
    /// @param _hash The hash to check against the active state.
    /// @param _currentTime The time at which the active state is being queried.
    /// @return True if the given hash matches the active state hash else false.
    function verifyHashAgainstActiveState(VersionManagerState storage _v, bytes32 _hash, uint256 _currentTime)
        internal
        view
        returns (bool)
    {
        return _hash == activeStateHash(_v, _currentTime);
    }

    /// @dev Returns true if the given hash matches the latest state hash else false.
    /// @param _v Version Manager Internal State
    /// @param _hash The hash to check against the latest state.
    /// @return True if the given hash matches the latest state hash else false.
    function verifyHashAgainstLatestState(VersionManagerState storage _v, bytes32 _hash) internal view returns (bool) {
        return _hash == latestStateHash(_v);
    }

    /// @dev Sets the latest state hash, but does not activate it immediately
    /// @param _v Version Manager Internal State
    /// @param _hash The hash to set as the latest state
    /// @param _currentTime The time at which the latest state is being set
    function setLatestState(VersionManagerState storage _v, bytes32 _hash, uint256 _currentTime) internal {
        // If the active state is in slot2, then move it to slot1
        if (_v.pendingHashActivationTime != 0 && _currentTime >= _v.pendingHashActivationTime) {
            _v.slot1 = _v.slot2;
        }

        // Set the latest state in slot2 (assuming slot1 is the active state)
        _v.slot2 = _hash;

        // If pendingHashActivationTime = 0, activeState = slot1. Refer to implementation of activeStateHash()
        delete _v.pendingHashActivationTime;
    }

    /// @dev Schedule the latest state to be activated at a given time. If the latest state is already scheduled for activation, this function does nothing.
    /// @param _v Version Manager Internal State
    /// @param _activationTime The time at which the latest state will become the active state.
    function setLatestStateForActivation(VersionManagerState storage _v, uint256 _activationTime) internal {
        if (_v.pendingHashActivationTime != 0) {
            // Existing pending state is already scheduled for activation
            return;
        }

        _v.pendingHashActivationTime = _activationTime;
        emit VersionManagerLatestStateSetForActivation(_activationTime, latestStateHash(_v));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.19;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v5.0._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v5.0._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v5.0._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v5.0._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v5.0._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Guards
/// @dev Common guard modifiers
interface IGuards {
    error NoSelfCall();
}