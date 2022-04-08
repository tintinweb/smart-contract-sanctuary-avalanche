/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ReentrancyGuard {

    /**
     * @dev We use a single lock for the whole contract.
     */
    bool private rentrancy_lock = false;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * @notice If you mark a function `nonReentrant`, you should also
     * mark it `external`. Calling one nonReentrant function from
     * another is not supported. Instead, you can implement a
     * `private` function doing the actual work, and a `external`
     * wrapper marked as `nonReentrant`.
     */
    modifier nonReentrant() {
        require(!rentrancy_lock);
        rentrancy_lock = true;
        _;
        rentrancy_lock = false;
    }

}

contract Roulette is Ownable, ReentrancyGuard {

    uint256[] red = [1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36];
    uint256[] black = [2,4,6,8,10,11,13,15,17,20,22,24,26,28,29,31,33,35];

    struct PlayerInfo {
        uint256 owedAmount;
        uint256[] participatedIds;
    }

    struct PlayerGameInfo {
        bool inGame;
        uint8[] gameTypes; //  0 - 1st12, 1 - 2nd12, 2 - 3rd12, 3 - 1to18, 4 - 19to36, 5 - even, 6 - odd, 7 - red, 8 - black, 9 - number
        uint8[] playerOutcomes;
        uint256[] betAmounts;
        bool[] won;
        uint256[] winAmounts;
        bool claimed;
    }

    struct GameInfo {
        uint256 gameId;
        uint256 endTimestamp;
        uint256 totalPlayers;
        uint256 totalBank;
        bool outcomeSet;
        uint8 realOutcome;
        uint256 totalWon;
        uint256 totalLost;
    }

    mapping (uint256 => mapping (address => PlayerGameInfo)) public playerGameInfo;
    mapping (address => PlayerInfo) public playerInfo;

    bool public gameActive;

    GameInfo[] public gameInfo;

    address public validator;

    uint256 public ONE_MINUTE = 60; // 60 seconds

    event BetPlaced(address player, uint256 gameId, uint8 playerOutcome, uint8 gameType);
    event WinClaimed(address player, uint256 payedAmount);

    constructor() {
        gameInfo.push(GameInfo({
            gameId: 0,
            endTimestamp: block.timestamp + ONE_MINUTE,
            totalPlayers: 0,
            totalBank: 0,
            outcomeSet: false,
            realOutcome: 0,
            totalWon: 0,
            totalLost: 0
        }));
        gameActive = true;
    }

    function getPlayerInfo(address user) external view returns (
    uint256[] memory participatedIds, 
    uint8[] memory gameType, 
    uint8[] memory playerOutcome,
    uint256[] memory betAmount,
    bool[] memory won,
    uint256[] memory winAmounts) {
        uint256 counter;
        for (uint256 i; i < playerInfo[user].participatedIds.length; i++) {
            counter += playerGameInfo[playerInfo[user].participatedIds[i]][user].gameTypes.length;
        }
        uint256 counter1;
        for (uint256 x; x <= counter; x ++) {
            for (uint256 y; y < playerInfo[user].participatedIds.length; y++) {
                for (uint256 z; z < playerGameInfo[playerInfo[user].participatedIds[y]][user].gameTypes.length; z++) {
                    participatedIds[counter1] = playerInfo[user].participatedIds[y];
                    gameType[counter1] = playerGameInfo[playerInfo[user].participatedIds[y]][user].gameTypes[z];
                    playerOutcome[counter1] = playerGameInfo[playerInfo[user].participatedIds[y]][user].playerOutcomes[z];
                    betAmount[counter1] = playerGameInfo[playerInfo[user].participatedIds[y]][user].betAmounts[z];
                    if (gameType[counter1] < 3) {
                        (won[counter1], winAmounts[counter1]) = check012(participatedIds[counter1], playerOutcome[counter1], betAmount[counter1]);
                    } else if (gameType[counter1] == 3 || gameType[counter1] == 4) {
                        (won[counter1], winAmounts[counter1]) = check34(participatedIds[counter1], playerOutcome[counter1], betAmount[counter1]);
                    } else if (gameType[counter1] == 5 || gameType[counter1] == 6) {
                        (won[counter1], winAmounts[counter1]) = check56(participatedIds[counter1], playerOutcome[counter1], betAmount[counter1]);
                    } else if (gameType[counter1] == 7 || gameType[counter1] == 8) {
                        (won[counter1], winAmounts[counter1]) = check78(participatedIds[counter1], playerOutcome[counter1], betAmount[counter1]);
                    } else {
                        (won[counter1], winAmounts[counter1]) = check9(participatedIds[counter1], playerOutcome[counter1], betAmount[counter1]);
                    }
                    counter1 ++;
                }
            }
        }
    }

    function getOwedAmount(address user) external view returns (uint256 amount, bool canClaim) {
        return(playerInfo[user].owedAmount, address(this).balance >= playerInfo[user].owedAmount);
    }

    function placeBet(uint8 _playerOutcome, uint8 _gameType) external payable nonReentrant {
        require(gameActive, "Game is currently paused");
        if (gameInfo[gameInfo.length-1].endTimestamp < block.timestamp) {
            _initNextGame();
        }
        if (_gameType < 9) {
            require(_playerOutcome != 0, "Invalid outcome for game type");
        }

        uint256 _currentGameId = gameInfo.length - 1;

        if (!playerGameInfo[_currentGameId][_msgSender()].inGame) {
            playerInfo[_msgSender()].participatedIds.push(_currentGameId);
            playerGameInfo[_currentGameId][_msgSender()].inGame = true;
            gameInfo[_currentGameId].totalPlayers ++;
        }

        gameInfo[_currentGameId].totalBank += msg.value;

        playerGameInfo[_currentGameId][_msgSender()].gameTypes.push(_gameType);
        playerGameInfo[_currentGameId][_msgSender()].playerOutcomes.push(_playerOutcome);
        playerGameInfo[_currentGameId][_msgSender()].betAmounts.push(msg.value);
    }

    function claimWin() external nonReentrant {
        uint256 totalPayableAmount;
        for (uint256 i; i < playerInfo[_msgSender()].participatedIds.length; i++) {
            if (!playerGameInfo[i][_msgSender()].claimed) {
                uint8 playerGameType;
                if (gameInfo[playerInfo[_msgSender()].participatedIds[i]].outcomeSet) {
                    for (uint256 x; x < playerGameInfo[i][_msgSender()].gameTypes.length; x++) {
                        playerGameType = playerGameInfo[i][_msgSender()].gameTypes[x];
                        bool win;
                        uint256 payForGame;
                        if (playerGameType < 3) {
                            (win, payForGame) = check012(playerInfo[_msgSender()].participatedIds[i] ,playerGameInfo[i][_msgSender()].playerOutcomes[x], playerGameInfo[i][_msgSender()].betAmounts[x]);
                        } else if (playerGameType == 3 || playerGameType == 4) {
                            (win, payForGame) = check34(playerInfo[_msgSender()].participatedIds[i] ,playerGameInfo[i][_msgSender()].playerOutcomes[x], playerGameInfo[i][_msgSender()].betAmounts[x]);
                        } else if (playerGameType == 5 || playerGameType == 6) {
                            (win, payForGame) = check56(playerInfo[_msgSender()].participatedIds[i] ,playerGameInfo[i][_msgSender()].playerOutcomes[x], playerGameInfo[i][_msgSender()].betAmounts[x]);
                        } else if (playerGameType == 7 || playerGameType == 8) {
                            (win, payForGame) = check78(playerInfo[_msgSender()].participatedIds[i] ,playerGameInfo[i][_msgSender()].playerOutcomes[x], playerGameInfo[i][_msgSender()].betAmounts[x]);
                        } else {
                            (win, payForGame) = check9(playerInfo[_msgSender()].participatedIds[i] ,playerGameInfo[i][_msgSender()].playerOutcomes[x], playerGameInfo[i][_msgSender()].betAmounts[x]);
                        }
                        playerGameInfo[i][_msgSender()].won.push(win);
                        if (win) {
                            playerGameInfo[i][_msgSender()].winAmounts.push(0);
                            gameInfo[playerInfo[_msgSender()].participatedIds[i]].totalWon += payForGame;
                            totalPayableAmount += payForGame;
                        } else {
                            gameInfo[playerInfo[_msgSender()].participatedIds[i]].totalLost += playerGameInfo[i][_msgSender()].betAmounts[i];
                        }
                    }
                }
                playerGameInfo[i][_msgSender()].claimed = true;
            }
        }
        if (totalPayableAmount > 0) {

        }
    }

    function claimOwed() external nonReentrant {
        if (address(this).balance >= playerInfo[_msgSender()].owedAmount) {
            playerInfo[_msgSender()].owedAmount = 0;
            payable(_msgSender()).transfer(playerInfo[_msgSender()].owedAmount);
        }
    }

    /// @dev 1st 12, 2nd 12, 3rd 12
    function check012(uint256 gameId, uint8 playerOutcome, uint256 betAmount) internal view returns (bool win, uint256 payout) {
        uint256 outcome = gameInfo[gameId].realOutcome;
        if (outcome !=0 && outcome < 13 && playerOutcome < 13) {
            win = true;
        } else if (outcome !=0 && outcome > 12 && outcome < 25 && playerOutcome > 12 && playerOutcome < 25) {
            win = true;
        } else if (outcome !=0 && outcome > 24 && playerOutcome > 24) {
            win = true;
        } else {
            win = false;
        }
        if (win) {
            payout = 37 * betAmount / 12;
        }
    }

    /// @dev 1 to 18, 19 to 36
    function check34(uint256 gameId, uint8 playerOutcome, uint256 betAmount) internal view returns (bool win, uint256 payout) {
        uint256 outcome = gameInfo[gameId].realOutcome;
        if (outcome !=0 && outcome < 19 && playerOutcome < 19) {
            win = true;
        } else if (outcome !=0 && outcome > 18 && playerOutcome > 19) {
            win = true;
        } else {
            win = false;
        }
        if (win) {
            payout = 37 * betAmount / 12;
        }
    }

    /// @dev even or odd
    function check56(uint256 gameId, uint8 playerOutcome, uint256 betAmount) internal view returns (bool win, uint256 payout) {
        uint256 outcome = gameInfo[gameId].realOutcome;
        if (outcome != 0 && outcome % 2 == playerOutcome % 2) {
            win = true;
        } else {
            win = false;
        }
        if (win) {
            payout = 37 * betAmount / 18;
        }
    }

    /// @dev red or black
    function check78(uint256 gameId, uint8 playerOutcome, uint256 betAmount) internal view returns (bool win, uint256 payout) {
        uint256 outcome = gameInfo[gameId].realOutcome;
        if (outcome != 0) {
            bool playerRed;
            bool gameRed;
            for (uint256 i; i < red.length; i ++) {
                if (red[i] == outcome) {
                    gameRed = true;
                }
                if (red[i] == playerOutcome) {
                    playerRed = true;
                }
            }
            win = gameRed == playerRed;
        } else {
            win = false;
        }
        if (win) {
            payout = 37 * betAmount / 18;
        }
    }

    function check9(uint256 gameId, uint8 playerOutcome, uint256 betAmount) internal view returns (bool win, uint256 payout) {
        win = gameInfo[gameId].realOutcome == playerOutcome;
        if (win) {
            payout = betAmount * 37;
        }
    }

    function _initNextGame() internal {
        uint256 _lastGameId = gameInfo.length - 1;
        require(gameInfo[_lastGameId].endTimestamp < block.timestamp, "Last game has not finished");
        _setGameOutcome();
        gameInfo.push(GameInfo({
            gameId: _lastGameId + 1,
            endTimestamp: block.timestamp + ONE_MINUTE,
            totalPlayers: 0,
            totalBank: 0,
            outcomeSet: false,
            realOutcome: 100,
            totalWon: 0,
            totalLost: 0
        }));
    }

    function _setGameOutcome() internal {
        gameInfo[gameInfo.length - 1].realOutcome = _generateOutcome();
        gameInfo[gameInfo.length - 1].outcomeSet = true;
    }

    function _generateOutcome() internal view returns (uint8 outcome) {
        outcome = uint8(uint(keccak256(abi.encodePacked(
            block.difficulty, 
            block.timestamp, 
            block.number))) % 36);
    }

    function payUser(address user, uint256 payableAmount) internal {
        if (address(this).balance >= payableAmount) {
            if (playerInfo[user].owedAmount > 0) {
                if (address(this).balance >= payableAmount + playerInfo[user].owedAmount) {
                    payableAmount += playerInfo[user].owedAmount;
                    playerInfo[user].owedAmount = 0;
                }
            }
            payable(user).transfer(payableAmount);
        } else {
            playerInfo[user].owedAmount += payableAmount;
        }
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}

}