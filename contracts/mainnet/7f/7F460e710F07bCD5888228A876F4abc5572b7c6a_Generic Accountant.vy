# @version 0.3.7

"""
@title Generic Accountant
@license GNU AGPLv3
@author yearn.finance
@notice
    This generic accountant is meant to serve as the accountant role
    for a Yearn V3 Vault. 
    https://github.com/yearn/yearn-vaults-v3/blob/master/contracts/VaultV3.vy

    It is designed to be able to be added to any number of vaults with any 
    underlying tokens. There is a degault fee config that will be used for 
    any strategy that reports through a vault thas has been added to this
    accountant. But also gives the ability for the fee_manager to choose 
    custom values for any value for any given strategy they want to.

    Funds received from the vaults can either be distributed to a specified
    fee_recipient or redeemed for the underlying asset and held withen this
    contract until distributed.
"""
from vyper.interfaces import ERC20

### INTERFACES ###
struct StrategyParams:
    activation: uint256
    last_report: uint256
    current_debt: uint256
    max_debt: uint256

interface IVault:
    def asset() -> address: view
    def strategies(strategy: address) -> StrategyParams: view
    def withdraw(amount: uint256, receiver: address, owner: address) -> uint256: nonpayable

### EVENTS ###

event VaultChanged:
    vault: address
    change: ChangeType

event UpdateDefaultFeeConfig:
    default_fee_config: Fee

event SetFutureFeeManager:
    future_fee_manager: address

event NewFeeManager:
    fee_manager: address

event UpdateFeeRecipient:
    old_fee_recipient: address
    new_fee_recipient: address

event UpdateCustomFeeConfig:
    vault: address
    strategy: address
    custom_config: Fee

event DistributeRewards:
    token: address
    rewards: uint256

### ENUMS ###

enum ChangeType:
    ADDED
    REMOVED

### STRUCTS ###

# Struct that holds all needed amounts to charge fees
# and issue refunds. All amounts are expressed in Basis points.
# i.e. 10_000 == 100%.
struct Fee:
    # Annual management fee to charge on strategy debt.
    management_fee: uint16
    # Performance fee to charge on reported gain.
    performance_fee: uint16
    # Ratio of reported loss to attempt to refund.
    refund_ratio: uint16
    # Max percent of the reported gain that the accountant can take.
    # A max_fee of 0 will mean non is enforced.
    max_fee: uint16
    # Bool set for custom fee configs
    custom: bool


### CONSTANTS ###

# 100% in basis points.
MAX_BPS: constant(uint256) = 10_000

# NOTE: A four-century period will be missing 3 of its 100 Julian leap years, leaving 97.
#       So the average year has 365 + 97/400 = 365.2425 days
#       ERROR(Julian): -0.0078
#       ERROR(Gregorian): -0.0003
#       A day = 24 * 60 * 60 sec = 86400 sec
#       365.2425 * 86400 = 31556952.0
SECS_PER_YEAR: constant(uint256) = 31_556_952  # 365.2425 days


### STORAGE ###

# Address in charge of the accountant.
fee_manager: public(address)
# Address to become the fee manager.
future_fee_manager: public(address)
# Address to distribute the accumulated fees to.
fee_recipient: public(address)

# Mapping of vaults that this serves as an accountant for.
vaults: public(HashMap[address, bool])
# Default config to use unless a custom one is set.
default_config: public(Fee)
# Mapping vault => strategy => custom Fee config
fees: public(HashMap[address, HashMap[address, Fee]])

@external
def __init__(
    fee_manager: address, 
    fee_recipient: address,
    default_management: uint16, 
    default_performance: uint16, 
    default_refund: uint16, 
    default_max: uint16
):
    """
    @notice Initialize the accountant and default fee config.
    @param fee_manager Address to be in charge of this accountant.
    @param default_management Default annual management fee to charge.
    @param default_performance Default performance fee to charge.
    @param default_refund Default refund ratio to give back on losses.
    @param default_max Default max fee to allow as a percent of gain.
    """
    assert fee_manager != empty(address), "ZERO ADDRESS"
    assert fee_recipient != empty(address), "ZERO ADDRESS"
    assert default_management <= self._management_fee_threshold(), "exceeds management fee threshold"
    assert default_performance <= self._performance_fee_threshold(), "exceeds performance fee threshold"

    # Set initial addresses
    self.fee_manager = fee_manager
    self.fee_recipient = fee_recipient

    # Set the default fee config
    self.default_config = Fee({
        management_fee: default_management,
        performance_fee: default_performance,
        refund_ratio: default_refund,
        max_fee: default_max,
        custom: False
    })

    log UpdateDefaultFeeConfig(self.default_config)


@external
def report(strategy: address, gain: uint256, loss: uint256) -> (uint256, uint256):
    """ 
    @notice To be called by a vault during the process_report in which the accountant
        will charge fees based on the gain or loss the strategy is reporting.
    @dev Can only be called by a vault that has been added to this accountant.
        Will default to the default_config for all amounts unless a custom config
        has been set for a specific strategy.
    @param strategy The strategy that is reporting.
    @param gain The profit the strategy is reporting if any.
    @param loss The loss the strategy is reporting if any.
    """
    # Make sure this is a valid vault.
    assert self.vaults[msg.sender], "!authorized"

    # Load the custom config to check the `custom` flag.
    # This should just be one slot.
    fee: Fee = self.fees[msg.sender][strategy]

    # If not use the default.
    if not fee.custom:
        fee = self.default_config

    total_fees: uint256 = 0
    total_refunds: uint256 = 0

    # Charge management fees no matter gain or loss.
    if fee.management_fee > 0:
        # Retrieve the strategies params from the vault.
        strategy_params: StrategyParams = IVault(msg.sender).strategies(strategy)
        # Time since last harvest.
        duration: uint256 = block.timestamp - strategy_params.last_report
        # management_fee is an annual amount, so charge based on the time passed.
        total_fees = (
            strategy_params.current_debt
            * duration
            * convert(fee.management_fee, uint256)
            / MAX_BPS
            / SECS_PER_YEAR
        )

    # Only charge performance fees if there is a gain.
    if gain > 0:
        total_fees += (gain * convert(fee.performance_fee, uint256)) / MAX_BPS
    else:
        # Means we should have a loss.
        if fee.refund_ratio > 0:
            # Cache the underlying asset the vault uses.
            asset: address = IVault(msg.sender).asset()
            # Give back either all we have or based on refund ratio.
            total_refunds = min(loss * convert(fee.refund_ratio, uint256) / MAX_BPS, ERC20(asset).balanceOf(self))

            if total_refunds > 0:
                # Approve the vault to pull the underlying asset.
                self.erc20_safe_approve(asset, msg.sender, total_refunds)
    
    # 0 Max fee means it is not enforced.
    if fee.max_fee > 0:
        # Ensure fee does not exceed more than the max_fee %.
        total_fees = min(gain * convert(fee.max_fee, uint256) / MAX_BPS, total_fees)

    return (total_fees, total_refunds)


@internal
def erc20_safe_approve(token: address, spender: address, amount: uint256):
    # Used only to send tokens that are not the type managed by this Vault.
    # HACK: Used to handle non-compliant tokens like USDT
    response: Bytes[32] = raw_call(
        token,
        concat(
            method_id("approve(address,uint256)"),
            convert(spender, bytes32),
            convert(amount, bytes32),
        ),
        max_outsize=32,
    )
    if len(response) > 0:
        assert convert(response, bool), "approval failed!"


@external
def add_vault(vault: address):
    """
    @notice Add a new vault for this accountant to charge fees for.
    @dev This is not used to set any of the fees for the specific 
    vault or strategy. Each fee will be set separately. 
    @param vault The address of a vault to allow to use this accountant.
    """
    assert msg.sender == self.fee_manager, "not fee manager"
    assert not self.vaults[vault], "already added"

    self.vaults[vault] = True

    log VaultChanged(vault, ChangeType.ADDED)


@external
def remove_vault(vault: address):
    """
    @notice Removes a vault for this accountant to charge fee for.
    @param vault The address of a vault to allow to use this accountant.
    """
    assert msg.sender == self.fee_manager, "not fee manager"
    assert self.vaults[vault], "not added"

    self.vaults[vault] = False

    log VaultChanged(vault, ChangeType.REMOVED)


@external
def update_default_config(
    default_management: uint16, 
    default_performance: uint16, 
    default_refund: uint16, 
    default_max: uint16
):
    """
    @notice Update the default config used for all strategies.
    @param default_management Default annual management fee to charge.
    @param default_performance Default performance fee to charge.
    @param default_refund Default refund ratio to give back on losses.
    @param default_max Default max fee to allow as a percent of gain.
    """
    assert msg.sender == self.fee_manager, "not fee manager"
    assert default_management <= self._management_fee_threshold(), "exceeds management fee threshold"
    assert default_performance <= self._performance_fee_threshold(), "exceeds performance fee threshold"

    self.default_config = Fee({
        management_fee: default_management,
        performance_fee: default_performance,
        refund_ratio: default_refund,
        max_fee: default_max,
        custom: False
    })

    log UpdateDefaultFeeConfig(self.default_config)


@external
def set_custom_config(
    vault: address,
    strategy: address,
    custom_management: uint16, 
    custom_performance: uint16, 
    custom_refund: uint16, 
    custom_max: uint16
):
    """
    @notice Used to set a custom fee amounts for a specific strategy.
        In a specific vault.
    @dev Setting this will cause the default config to be overridden.
    @param vault The vault the strategy is hooked up to.
    @param strategy The strategy to customize.
    @param custom_management Custom annual management fee to charge.
    @param custom_performance Custom performance fee to charge.
    @param custom_refund Custom refund ratio to give back on losses.
    @param custom_max Custom max fee to allow as a percent of gain.
    """
    assert msg.sender == self.fee_manager, "not fee manager"
    assert self.vaults[vault], "vault not added"
    assert custom_management <= self._management_fee_threshold(), "exceeds management fee threshold"
    assert custom_performance <= self._performance_fee_threshold(), "exceeds performance fee threshold"

    # Set this strategies custom config.
    self.fees[vault][strategy] = Fee({
        management_fee: custom_management,
        performance_fee: custom_performance,
        refund_ratio: custom_refund,
        max_fee: custom_max,
        custom: True
    })

    log UpdateCustomFeeConfig(vault, strategy, self.fees[vault][strategy])


@external
def remove_custom_config(vault: address, strategy: address):
    """
    @notice Removes a previously set custom config for a strategy.
    @param strategy The strategy to remove custom setting for.
    """
    assert msg.sender == self.fee_manager, "not fee manager"
    assert self.fees[vault][strategy].custom, "No custom fees set"

    # Set all the strategies custom fees to 0.
    self.fees[vault][strategy] = Fee({
        management_fee: 0,
        performance_fee: 0,
        refund_ratio: 0,
        max_fee: 0,
        custom: False
    })

    # Emit relevant event.
    log UpdateCustomFeeConfig(vault, strategy, self.fees[vault][strategy])


@external
def withdraw_underlying(vault: address, amount: uint256):
    """
    @notice Can be used by the fee manager to simply withdraw the underlying
        asset from a vault it charges fees for.
    @dev Refunds are payed in the underlying but fees are charged in the vaults
        token. So management may want to fee some funds to allow for refunds to 
        work across all vaults of the same underlying.
    @param vault The vault to redeem from.
    @param amount The amount in the underlying to withdraw.
    """
    assert msg.sender == self.fee_manager, "not fee manager"
    IVault(vault).withdraw(amount, self, self)


@external
def distribute(token: address) -> uint256:
    """
    @notice used to withdraw accumulated fees to the designated recipient.
    @dev This can be used to withdraw the vault tokens or underlying tokens
        that had previously been withdrawn.
    @param token The token to distribute.
    @return The amount of token distributed.
    """
    assert msg.sender == self.fee_manager, "not fee manager"

    rewards: uint256 = ERC20(token).balanceOf(self)
    self._erc20_safe_transfer(token, self.fee_recipient, rewards)

    log DistributeRewards(token, rewards)
    return rewards


@internal
def _erc20_safe_transfer(token: address, receiver: address, amount: uint256):
    # Used only to send tokens that are not the type managed by this Vault.
    # HACK: Used to handle non-compliant tokens like USDT
    response: Bytes[32] = raw_call(
        token,
        concat(
            method_id("transfer(address,uint256)"),
            convert(receiver, bytes32),
            convert(amount, bytes32),
        ),
        max_outsize=32,
    )
    if len(response) > 0:
        assert convert(response, bool), "Transfer failed!"


@external
def set_future_fee_manager(future_fee_manager: address):
    """
    @notice Step 1 of 2 to set a new fee_manager.
    @dev The address is set to future_fee_manager and will need to
        call accept_fee_manager in order to update the actual fee_manager.
    @param future_fee_manager Address to set to future_fee_manager.
    """
    assert msg.sender == self.fee_manager, "not fee manager"
    assert future_fee_manager != empty(address), "ZERO ADDRESS"
    self.future_fee_manager = future_fee_manager

    log SetFutureFeeManager(future_fee_manager)


@external
def accept_fee_manager():
    """
    @notice to be called by the future_fee_manager to accept the role change.
    """
    assert msg.sender == self.future_fee_manager, "not future fee manager"
    self.fee_manager = self.future_fee_manager
    self.future_fee_manager = empty(address)

    log NewFeeManager(msg.sender)


@external
def set_fee_recipient(new_fee_recipient: address):
    """
    @notice Set a new address to receive distributed rewards.
    @param new_fee_recipient Address to receive distributed fees.
    """
    assert msg.sender == self.fee_manager, "not fee manager"
    assert new_fee_recipient != empty(address), "ZERO ADDRESS"
    old_fee_recipient: address = self.fee_recipient
    self.fee_recipient = new_fee_recipient

    log UpdateFeeRecipient(old_fee_recipient, new_fee_recipient)


@view
@external
def performance_fee_threshold() -> uint16:
    """
    @notice External function to get the max a performance fee can be.
    @return Max performance fee the accountant can charge.
    """
    return self._performance_fee_threshold()


@view
@internal
def _performance_fee_threshold() -> uint16:
    """
    @notice Internal function to get the max a performance fee can be.
    @return Max performance fee the accountant can charge.
    """
    return 5_000


@view
@external
def management_fee_threshold() -> uint16:
    """
    @notice External function to get the max a management fee can be.
    @return Max management fee the accountant can charge.
    """
    return self._management_fee_threshold()


@view
@internal
def _management_fee_threshold() -> uint16:
    """
    @notice Internal function to get the max a management fee can be.
    @return Max management fee the accountant can charge.
    """
    return 200