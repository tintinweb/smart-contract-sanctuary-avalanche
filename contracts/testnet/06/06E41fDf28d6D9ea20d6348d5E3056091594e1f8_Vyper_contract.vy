# @version ^0.3.3

# USDC interface
interface i_erc20:
    def approve(_spender: address, _value: uint256) -> bool: nonpayable
    def balanceOf(_spender: address) -> uint256: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable

# ERC20Play interface
interface i_erc20_play:
    def get(_spender: address) -> bool: nonpayable

s_change_cancel_fee: uint256

# Chain ID
s_chain_id: public(uint256)

# USDC contract address
s_erc20_token_address: public(address)

# ERC20Play contract address
s_erc20_play_token_address: public(address)

# State variables
s_addresses_set: bool
s_admin_address: public(address)
s_withdraw_address: public(address)

# @notice
# [_meeting_key] = true
s_meeting_setup_done: HashMap[String[18], bool]

# @notice
# [_meeting_key] = [-1,0,1,1,1,]
s_meeting_race_status: HashMap[String[18], DynArray[uint256, 20]]

# @notice
# [_meeting_key] = [[1,0,1,1,1,],[1,0,1,1,1,]]
s_meeting_race_runner_status: HashMap[String[18], DynArray[DynArray[uint256, 50], 20]]

# @notice
# [_meeting_key] = [[0,0,0,0,0,0],[0,0,0,0,0,0]]
s_meeting_race_runner_amounts: HashMap[String[18], DynArray[DynArray[uint256, 50], 20]]

# [real/play]["2022-02-23-HKG-HAP"][1] += 1000
s_win_bets_race: HashMap[String[4], HashMap[String[18], HashMap[uint256, uint256]]]

# [real/play]]["2022-02-23-HKG-HAP"][1][1] += 500
s_win_bets_race_runner: HashMap[String[4], HashMap[String[18], HashMap[uint256, HashMap[uint256, uint256]]]]

# @notice
# [real/play]][user_address][_wl_operator][_meeting_key] = True/False
s_win_bets_user_lookup: HashMap[String[4], HashMap[address, HashMap[uint256, HashMap[String[18], bool]]]]

# @notice
# [real/play]][user_address][_wl_operator][_meeting_key][_race][_runner] = 0/100000
s_win_bets_user: HashMap[String[4], HashMap[address, HashMap[uint256, HashMap[String[18], DynArray[DynArray[uint256, 50], 20]]]]]


# @notice setup the contract
# @param _usdc_adddress address on the USDC contract
@external
def __init__(_chain_id: uint256, _erc20_token_address: address, _erc20_play_token_adddress: address):
    self.s_chain_id = _chain_id
    self.s_erc20_token_address = _erc20_token_address
    self.s_erc20_play_token_address = _erc20_play_token_adddress
    self.s_change_cancel_fee = 1500


# @notice Initial call to setup the addresses
@external
def setAddresses(_address: address):
    assert self.s_addresses_set == False, "Addresses have been set"
    self.s_admin_address = _address
    self.s_withdraw_address = _address
    self.s_addresses_set = True


# @notice Allow the contract to receive ERC20 Play tokens
@external
def getERC20Play():
    success: bool = i_erc20_play(self.s_erc20_play_token_address).get(msg.sender)
    assert success == True, "Address did not receive ERC20 Play tokens"


# @notice Allow the contract to receive ERC20 tokens
# @param _amount The amount of ERC20 tokens to send to the contract
@internal
def _receiveTokens(_address: address, _amount: uint256):
    success: bool = i_erc20(_address).transferFrom(msg.sender, self, _amount)
    assert success == True, "Contract did not receive tokens"


# @notice Allow the contract to receive ERC20
# @param _amount The amount of ERC20 to send to the contract
@external
def receiveTokens(_address: address, _amount: uint256):
    self._receiveTokens(_address, _amount)


# @notice Setup the internals of the contract
# @param _meeting_key What meeting are we talking about - 2022-02-23-HKG-HAP
# @param _meeting_setup The array of races and number of runners [6, 6, 7, 8, 8, 14, 10]
@external
def setup(_meeting_key: String[18], _meeting_setup: DynArray[uint256, 20]):
    assert self.s_admin_address == msg.sender, "You are not the admin address"
    assert self.s_meeting_setup_done[_meeting_key] == False, "Meeting already setup"

    for _race in _meeting_setup:
        _bet_amounts: DynArray[uint256, 50] = []
        _runners: DynArray[uint256, 50] = []
        for i in range(100):
            if i != _race:
                _bet_amounts.append(0)
                _runners.append(1)
            else:
                break

        self.s_meeting_race_status[_meeting_key].append(1)
        self.s_meeting_race_runner_amounts[_meeting_key].append(_bet_amounts)
        self.s_meeting_race_runner_status[_meeting_key].append(_runners)

    self.s_meeting_setup_done[_meeting_key] = True


# @notice Set the chain_id
# @param _chain_id What is the chain_id
@external
def setChainId(_chain_id: uint256):
    assert self.s_admin_address == msg.sender, "You are not the admin address"
    self.s_chain_id = _chain_id


# @notice Get the meeting_race_status for a given meeting_key
# @dev Is a convenience method for accessing contract state.
# @param _meeting_key What meeting are we talking about - 2022-02-23-HKG-HAP
@external
@view
def raceStatus(_meeting_key: String[18]) -> (DynArray[uint256, 20]):
    return self.s_meeting_race_status[_meeting_key]


# @notice Set a race status
# @param _meeting What meeting are we talking about - 2022-02-23-HKG-HAP
# @param _race Which race number to change the status of, 0 indexed
# @param _status 1 is active, 0 is closed
@external
def setRaceStatus(_meeting_key: String[18], _race: uint256, _status: uint256):
    assert self.s_admin_address == msg.sender, "You are not the admin address"
    self.s_meeting_race_status[_meeting_key][_race] = _status


# @notice Get the meeting_race_runner_status for a given meeting_key
# @dev Is a convenience method for accessing contract state.
# @param _meeting_key What meeting are we talking about - 2022-02-23-HKG-HAP
@external
@view
def raceRunnerStatus(_meeting_key: String[18]) -> (DynArray[DynArray[uint256, 50], 20]):
    return self.s_meeting_race_runner_status[_meeting_key]


# @notice Set a race/runner status
# @param _meeting What meeting are we talking about - 2022-02-23-HKG-HAP
# @param _race Which race number to change the status of, 0 indexed
# @param _runner Which runner number to change the status of, 0 indexed
# @param _status 1 is active, 0 is closed
@external
def setRaceRunnerStatus(_meeting_key: String[18], _race: uint256, _runner: uint256, _status: uint256):
    assert self.s_admin_address == msg.sender, "You are not the admin address"
    assert self.s_meeting_race_status[_meeting_key][_race] == 1, "Race not active"

    self.s_meeting_race_runner_status[_meeting_key][_race][_runner] = _status


# @notice Set the admin address
# @dev Only the admin address can acess various functions on the contract
# @param _address Wallet address you want to be the admin
@external
def setAdminAddress(_address: address):
    # The factory seems to set the admin/withdraw address as empty(address)
    # we need to be able to set these when the factory deploys the contract
    if self.s_admin_address == empty(address):
        self.s_admin_address = _address
    else:
        assert self.s_admin_address == msg.sender, "You are not the admin address"
        self.s_admin_address = _address


# @notice Set the withdraw_address
# @dev Use sparingly, this will receive the contract funds
# @param _address Wallet address you want funds to go to
@external
def setWithdrawAddress(_address: address):
    # The factory seems to set the admin/withdraw address as empty(address)
    # we need to be able to set these when the factory deploys the contract
    if self.s_withdraw_address == empty(address):
        self.s_withdraw_address = _address
    else:
        assert self.s_admin_address == msg.sender, "You are not the admin address"
        self.s_withdraw_address = _address


# @notice Set the ERC20 contract address
# @param _address of ERC20 contract
@external
def setERC20Address(_address: address):
    # The factory seems to set the admin/withdraw address as empty(address)
    # we need to be able to set these when the factory deploys the contract
    if self.s_erc20_token_address == empty(address):
        self.s_erc20_token_address = _address
    else:
        assert self.s_admin_address == msg.sender, "You are not the admin address"
        self.s_erc20_token_address = _address


# @notice Set the ERC20 play money contract address
# @param _address Wallet address you want funds to go to
@external
def setERC20PlayAddress(_address: address):
    # The factory seems to set the admin/withdraw address as empty(address)
    # we need to be able to set these when the factory deploys the contract
    if self.s_erc20_play_token_address == empty(address):
        self.s_erc20_play_token_address = _address
    else:
        assert self.s_admin_address == msg.sender, "You are not the admin address"
        self.s_erc20_play_token_address = _address


# @notice Set the s_change_cancel_fee
# @param _change_cancel_fee The fee in basis points i.e 1500 is 15%
@external
def setChangeCancelFee(_change_cancel_fee: uint256):
    assert self.s_admin_address == msg.sender, "You are not the admin address"
    self.s_change_cancel_fee = _change_cancel_fee


# @notice Return the ERC20 token address given bet type
# @param _bet_type play/real money bet
@internal
def _erc20_address(_bet_type: String[4]) -> address:
    _address: address = self.s_erc20_play_token_address
    if _bet_type == "real":
        _address = self.s_erc20_token_address
    return _address


# @notice Fetch race bets for given params
# @param _bet_type play/real money bet
# @param _wl_operator
# @param _meeting_key
# @param _race
@external
@view
def winBetRace(_bet_type: String[4], _meeting_key: String[18], _race: uint256) -> uint256:
    return self.s_win_bets_race[_bet_type][_meeting_key][_race]


# @notice Fetch race bets for given params
# @param _wl_operator
# @param _meeting_key
# @param _race
@external
@view
def winBetRaceRunner(_bet_type: String[4], _meeting_key: String[18], _race: uint256, _runner: uint256) -> uint256:
    return self.s_win_bets_race_runner[_bet_type][_meeting_key][_race][_runner]


# @notice Fetch race bets for given params
# @param _wl_operator
# @param _meeting_key
# @param _race
# @param _runner
@external
@view
def winBetUser(_bet_type: String[4], _wl_operator: uint256, _meeting_key: String[18], _race: uint256) -> DynArray[uint256, 50]:
    return self.s_win_bets_user[_bet_type][msg.sender][_wl_operator][_meeting_key][_race]


event WinBetUser:
    bet_type: String[4]
    chain_id: uint256
    meeting_key: String[18]
    race: uint256
    runner: uint256
    action: String[20]
    wallet: address
    amount: uint256
    winner: bool
    payout: uint256
    wl_operator: uint256
    wl_operator_fee: uint256


event WinBetRunner:
    bet_type: String[4]
    chain_id: uint256
    meeting_key: String[18]
    race: uint256
    runner: uint256
    amount: uint256
    winner: bool


# @notice Address bets on a win
# @param _bet_type play/real money bet
# @param _wl_operator What whitelist frontend is sending the bet
# @param _meeting_key What meeting are we talking about - 2022-02-23-HKG-HAP
# @param _race Which race number to bet on, 0 indexed
# @param _runner Which runner number to bet on, 0 indexed
@external
@nonreentrant("lock")
def createWinBet(_bet_type: String[4], _wl_operator: uint256, _meeting_key: String[18], _race: uint256, _runner: uint256, _bet_amount: uint256):
    assert self.s_meeting_race_status[_meeting_key][_race] == 1, "Race not active"
    assert self.s_meeting_race_runner_status[_meeting_key][_race][_runner] == 1, "Runner not active"

    erc20_address: address = self._erc20_address(_bet_type)
    assert i_erc20(erc20_address).balanceOf(msg.sender) > _bet_amount, "Not enough funds"

    # Check to see whether address has made a bet on this _wl_operator/_meeting_key combo
    # If not setup the race/runner bet array so that the user can bet
    if (self.s_win_bets_user_lookup[_bet_type][msg.sender][_wl_operator][_meeting_key] == False):
        self.s_win_bets_user[_bet_type][msg.sender][_wl_operator][_meeting_key] = self.s_meeting_race_runner_amounts[_meeting_key]
        self.s_win_bets_user_lookup[_bet_type][msg.sender][_wl_operator][_meeting_key] = True

    self.s_win_bets_race[_bet_type][_meeting_key][_race] += _bet_amount
    self.s_win_bets_race_runner[_bet_type][_meeting_key][_race][_runner] += _bet_amount
    self.s_win_bets_user[_bet_type][msg.sender][_wl_operator][_meeting_key][_race][_runner] += _bet_amount
    self._receiveTokens(erc20_address, _bet_amount)

    log WinBetUser(
        _bet_type,
        self.s_chain_id,
        _meeting_key,
        _race,
        _runner,
        "create",
        msg.sender,
        self.s_win_bets_user[_bet_type][msg.sender][_wl_operator][_meeting_key][_race][_runner],
        False, 0, _wl_operator, 0
    )

    log WinBetRunner(
        _bet_type,
        self.s_chain_id,
        _meeting_key,
        _race,
        _runner,
        self.s_win_bets_race_runner[_bet_type][_meeting_key][_race][_runner],
        False
    )


# @notice Change the win bets from one runner to another
# @dev We need to track an internal and external state, internal is for bet payout
#      external is for presentation to a user
# @param _bet_type play/real money bet
# @param _wl_operator What whitelist frontend is sending the bet
# @param _meeting_key What meeting are we talking about - 2022-02-23-HKG-HAP
# @param _race Which race number to bet on, 0 indexed
# @param _from_runner Which runner you hace placed a bet on
# @param _to_runner Which runner are you changing your bet to
@external
def changeWinBet(_bet_type: String[4], _wl_operator: uint256, _meeting_key: String[18], _race: uint256, _from_runner: uint256, _to_runner: uint256):
    assert self.s_meeting_race_status[_meeting_key][_race] == 1, "Race not active"
    assert self.s_meeting_race_runner_status[_meeting_key][_race][_from_runner] == 1, "From runner not active"
    assert self.s_meeting_race_runner_status[_meeting_key][_race][_to_runner] == 1, "To runner not active"

    erc20_address: address = self._erc20_address(_bet_type)
    bet_amount: uint256 = self.s_win_bets_user[_bet_type][msg.sender][_wl_operator][_meeting_key][_race][_from_runner]

    # There is a fee for changing your bet
    takeout: uint256 = bet_amount * self.s_change_cancel_fee / 10000
    bet_amount_new: uint256 =  bet_amount - takeout

    self.s_win_bets_race[_bet_type][_meeting_key][_race] -= bet_amount
    self.s_win_bets_race_runner[_bet_type][_meeting_key][_race][_from_runner] -= bet_amount

    self.s_win_bets_race[_bet_type][_meeting_key][_race] += bet_amount_new
    self.s_win_bets_race_runner[_bet_type][_meeting_key][_race][_to_runner] += bet_amount_new

    self.s_win_bets_user[_bet_type][msg.sender][_wl_operator][_meeting_key][_race][_from_runner] = 0
    self.s_win_bets_user[_bet_type][msg.sender][_wl_operator][_meeting_key][_race][_to_runner] += bet_amount_new

    log WinBetUser(
        _bet_type,
        self.s_chain_id,
        _meeting_key,
        _race,
        _from_runner,
        "cancel",
        msg.sender,
        self.s_win_bets_user[_bet_type][msg.sender][_wl_operator][_meeting_key][_race][_from_runner],
        False, 0, _wl_operator, 0
    )

    log WinBetRunner(
        _bet_type,
        self.s_chain_id,
        _meeting_key,
        _race,
        _from_runner,
        self.s_win_bets_race_runner[_bet_type][_meeting_key][_race][_from_runner],
        False
    )

    log WinBetUser(
        _bet_type,
        self.s_chain_id,
        _meeting_key,
        _race,
        _to_runner,
        "create",
        msg.sender,
        self.s_win_bets_user[_bet_type][msg.sender][_wl_operator][_meeting_key][_race][_to_runner],
        False, 0, _wl_operator, 0
    )

    log WinBetRunner(
        _bet_type,
        self.s_chain_id,
        _meeting_key,
        _race,
        _to_runner,
        self.s_win_bets_race_runner[_bet_type][_meeting_key][_race][_to_runner],
        False
    )


# @notice Cancel the win bet on a runner
# @param _bet_type play/real money bet
# @param _wl_operator What whitelist frontend is sending the bet
# @param _meeting_key What meeting are we talking about - 2022-02-23-HKG-HAP
# @param _race Which race number to cancel bet on, 0 indexed
# @param _runner Which runner to cancel bet on
@external
def cancelWinBet(_bet_type: String[4], _wl_operator: uint256, _meeting_key: String[18], _race: uint256, _runner: uint256):
    assert self.s_meeting_race_status[_meeting_key][_race] == 1, "Race not active"
    assert self.s_meeting_race_runner_status[_meeting_key][_race][_runner] == 1, "Runner not active"

    erc20_address: address = self._erc20_address(_bet_type)

    bet_amount: uint256 = self.s_win_bets_user[_bet_type][msg.sender][_wl_operator][_meeting_key][_race][_runner]

    self.s_win_bets_race[_bet_type][_meeting_key][_race] -= bet_amount
    self.s_win_bets_race_runner[_bet_type][_meeting_key][_race][_runner] -= bet_amount
    self.s_win_bets_user[_bet_type][msg.sender][_wl_operator][_meeting_key][_race][_runner] = 0

    # There is a fee for cancelling your bet
    takeout: uint256 = bet_amount * self.s_change_cancel_fee / 10000
    amount_return: uint256 =  bet_amount - takeout

    # Return the ERC20 less the takeout
    i_erc20(erc20_address).approve(self, amount_return)
    i_erc20(erc20_address).transferFrom(self, msg.sender, amount_return)

    log WinBetUser(
        _bet_type,
        self.s_chain_id,
        _meeting_key,
        _race,
        _runner,
        "cancel",
        msg.sender,
        self.s_win_bets_user[_bet_type][msg.sender][_wl_operator][_meeting_key][_race][_runner],
        False, 0, _wl_operator, 0
    )

    log WinBetRunner(
        _bet_type,
        self.s_chain_id,
        _meeting_key,
        _race,
        _runner,
        self.s_win_bets_race_runner[_bet_type][_meeting_key][_race][_runner],
        False
    )


@external
def resultWinBet(_meeting_key: String[18], _race: uint256, _winners: DynArray[uint256, 5]):
    pass