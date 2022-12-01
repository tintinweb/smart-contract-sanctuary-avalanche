# @version >=0.3.7
# @author Rafael Abuawad <[email protected]>

from vyper.interfaces import ERC20
from vyper.interfaces import ERC20Detailed

implements: ERC20
implements: ERC20Detailed

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

# @dev name of the token ("Wrapped AVAX")
name: public(String[32])

# @dev symbol or ticker of the token ("WAVAX")
symbol: public(String[32])

# @dev the amount of decimals the token contains
decimals: public(uint8)

# @dev the balance of a particular address
balanceOf: public(HashMap[address, uint256])

# @dev addresses can allow other's addresses to spend their tokens
allowance: public(HashMap[address, HashMap[address, uint256]])

# @dev the number of tokens in circulation
totalSupply: public(uint256)


@external
def __init__():
    self.name = "Wrapped AVAX"
    self.symbol = "AVAX"
    self.decimals = 18


@internal
def _mint(_to: address, _value: uint256):
    assert _to != empty(address)
    self.totalSupply += _value
    self.balanceOf[_to] += _value
    log Transfer(empty(address), _to, _value)


@internal
def _burn(_to: address, _value: uint256):
    assert _to != empty(address)
    self.totalSupply -= _value
    self.balanceOf[_to] -= _value
    send(_to, _value)
    log Transfer(_to, empty(address), _value)


@external
def transfer(_to : address, _value : uint256) -> bool:
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value

    self.allowance[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True


@external
@payable
def mint():
    self._mint(msg.sender, msg.value)


@external
def burn(_value: uint256):
    self._burn(msg.sender, _value)


@external
@payable
def __default__():
    self._mint(msg.sender, msg.value)