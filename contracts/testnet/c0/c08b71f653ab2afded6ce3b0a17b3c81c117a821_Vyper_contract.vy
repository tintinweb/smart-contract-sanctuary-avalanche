from vyper.interfaces import ERC20

owner: public(address) 
tokens: public(HashMap[address,bool])
tokenList: public(DynArray[address,512])

event Deposit:
    token: indexed(address)
    to: indexed(address)
    amount: uint256

event Withdraw:
    token: indexed(address)
    to: indexed(address)
    amount: uint256

event TokenRegistered:
    token: indexed(address)

@external
def __init__():
	self.owner = msg.sender

@external
def deposit( token: address, to:address, amount: uint256 ):
	assert self.tokens[token], "Cannot deposit an unregistered token"
	ERC20(token).transferFrom(msg.sender, self, amount)
	log Deposit( token, to, amount )
	
@external 
def withdraw( token: address, to: address, amount: uint256 ):
	assert msg.sender == self.owner, "Only the contract owner can withdraw tokens"
	ERC20(token).transferFrom(self, to, amount)
	log Withdraw( token, to, amount )

@external
def registerToken( token: address ):
	assert msg.sender == self.owner, "Only the contract owner can register new tokens"
	self.tokens[token] = True
	self.tokenList.append(token)
	log TokenRegistered(token)

@external
def numTokens() -> uint256:
	return len(self.tokenList)