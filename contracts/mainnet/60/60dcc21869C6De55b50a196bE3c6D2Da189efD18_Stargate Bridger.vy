# @version 0.3.7
"""
@title Stargate Bridger
@author Curve Finance
@license MIT
"""
from vyper.interfaces import ERC20


interface StargateRouter:
    def quoteLayerZeroFee(
        dst_chain_id: uint16,
        function_type: uint8,
        to: Bytes[256],
        payload: Bytes[256],
        params: LZParams
    ) -> uint256: view
    def swap(
        dst_chain_id: uint16,
        src_pool_id: uint256,
        dst_pool_id: uint256,
        refund: address,
        amount_ld: uint256,
        min_amount_ld: uint256,
        params: LZParams,
        to: Bytes[256],
        payload: Bytes[256]
    ): payable


event CommitOwnership:
    owner: address

event AcceptOwnership:
    owner: address

event AssetBridged:
    token: indexed(address)
    amount: uint256


struct LZParams:
    gaz: uint256
    amt: uint256
    addr: Bytes[128]


ETH_CHAIN_ID: constant(uint16) = 101


ROUTER: public(immutable(address))
TOKEN: public(immutable(address))


start: uint256
receiver: public(address)

owner: public(address)
future_owner: public(address)


@external
def __init__(router: address, receiver: address, token: address):
    self.owner = msg.sender
    self.receiver = receiver

    ROUTER = router
    TOKEN = token

    log AcceptOwnership(msg.sender)


@payable
@external
def __default__():
    assert len(msg.data) == 0


@external
def burn(coin: address) -> bool:
    assert msg.sender == self.owner and coin == TOKEN

    start: uint256 = self.start
    assert block.timestamp > start + 1800

    amount: uint256 = ERC20(coin).balanceOf(self)
    if amount == 0:
        amount = ERC20(coin).balanceOf(msg.sender)
        assert ERC20(coin).transferFrom(msg.sender, self, amount)
    
    if start == 0:
        ERC20(coin).transfer(msg.sender, ERC20(coin).balanceOf(self) - amount / 100)
        amount = amount / 100
        
        self.start = block.timestamp
    
    receiver: address = self.receiver
    fee: uint256 = StargateRouter(ROUTER).quoteLayerZeroFee(
        ETH_CHAIN_ID,
        1,
        slice(convert(receiver, bytes32), 12, 20),
        b"",
        LZParams({gaz: 0, amt: 0, addr: slice(convert(receiver, bytes32), 12, 20)}),
    )
    assert ERC20(coin).approve(ROUTER, amount)

    StargateRouter(ROUTER).swap(
        ETH_CHAIN_ID,
        1,
        1,
        receiver,
        amount,
        999 * amount / 1000,
        LZParams({gaz: 0, amt: 0, addr: slice(convert(receiver, bytes32), 12, 20)}),
        slice(convert(receiver, bytes32), 12, 20),
        b"",
        value=fee
    )

    log AssetBridged(coin, amount)
    return True


@external
def commit_transfer_ownership(future_owner: address):
    assert msg.sender == self.owner

    self.future_owner = future_owner
    log CommitOwnership(future_owner)


@external
def accept_transfer_ownership():
    assert msg.sender == self.future_owner

    self.owner = msg.sender
    log AcceptOwnership(msg.sender)


@external
def recover(coin: address):
    assert msg.sender == self.owner
    
    if coin == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE:
        raw_call(msg.sender, b"", value=self.balance)
    else:
        assert ERC20(coin).transfer(msg.sender, ERC20(coin).balanceOf(self))


@external
def set_root_receiver(receiver: address):
    assert msg.sender == self.owner
    assert receiver != empty(address)

    self.receiver = receiver