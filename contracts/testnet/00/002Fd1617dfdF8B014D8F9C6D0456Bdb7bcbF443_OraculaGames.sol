/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

library SafeBEP20 {
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
    unchecked {
        uint256 oldAllowance = token.allowance(address(this), spender);
        require(oldAllowance >= value, "SafeBEP20: decreased allowance below zero");
        uint256 newAllowance = oldAllowance - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

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

contract OraculaGames is Context, Ownable {
    using SafeBEP20 for IBEP20;

    struct EventFinances {
        bool processed;
        uint256[] outcomeIds;
        uint256[] betAmounts;
        mapping(uint256 => uint256) totalForOutcome;
        uint256 total;
        uint256 finalPrice;
    }

    struct EventInfo {
        bool exists;
        uint256 realOutcome;
        bool outcomeSet;
        uint256 power;
        uint256 startTime;
        uint256 endTime;
        uint256 totalBets;
        address creator;
        uint256 oraculaFee;
        uint256 creatorFee;
        uint256[] outcomeIds;
        bool refundAllowed;
        // info
        uint256 totalNumOfBets;
        uint256 totalNumOfPlayers;
    }

    struct PlayerInfo {
        bool inGame;
        IBEP20[] tokens;
        uint256[] betAmount;
        uint256[] timestamp;
        uint256 outcome;
        bool winClaimed;
    }

    IBEP20 public oraculaToken;
    mapping(IBEP20 => bool) private allowedTokens;
    mapping(uint256 => IBEP20) private eventToken;
    IBEP20[] private arrayOfEventTokens;

    uint256 private eventCounter;
    mapping(uint256 => EventInfo) public eventInfo;
    mapping(uint256 => mapping(IBEP20 => EventFinances)) public eventFinances;

    mapping(uint256 => mapping(address => PlayerInfo)) public playerInfo;

    address[] allPlayers;
    mapping (address => bool) private addedToAllPlayers;


    mapping(uint256 => mapping(uint256 => uint256)) public eventOutcomeIds;
    mapping(uint256 => mapping(uint256 => uint256)) private reverseOutcomes;
    mapping(uint256 => mapping(uint256 => bool)) private eventOutcomeExists;

    uint256 immutable denominator = 1000;
    address oraculaSystem;
    address betMarket;

    bool public contractActive = true;
    bool public activeCouldBeChanged = true;
    uint256 private emergencyStopCount;

    event BetPlaced(address user, uint256 amount, uint256 outcomeId);
    event EventCreated(uint256 eventId, address creator, uint256 creatorFee, uint256 oraculaFee);
    event EventFinished(uint256 eventId, uint256 realOutcome);
    event WinClaimed(address user, uint256 eventId);
    event BetTransferres(address from, address to);
    event RefundClaimed(address user, uint256 eventId);

    modifier onlyOracula() {
        require(_msgSender() == oraculaSystem || _msgSender() == owner(), "Contract: Authorisation failed");
        _;
    }

    modifier verifyEvent(uint256 _eventId) {
        require(eventInfo[_eventId].exists, "Event does not exist!");
        _;
    }

    constructor(address _oraculaSystem) {
        oraculaSystem = _oraculaSystem;
    }

    /// @dev For debugging

    function getEventFinances(uint256 _eventId, IBEP20 _token) external view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256, uint256) {
        uint256[] memory tFO = new uint256[](eventInfo[_eventId].outcomeIds.length);
        for (uint256 i; i < tFO.length; i ++) {
            tFO[i] = eventFinances[_eventId][_token].totalForOutcome[i];
        }
        return (
            eventFinances[_eventId][_token].outcomeIds,
            eventFinances[_eventId][_token].betAmounts,
            tFO,
            eventFinances[_eventId][_token].total,
            eventFinances[_eventId][_token].finalPrice
        );
    }


    /// @dev MAIN FUNCTIONS

    /// @dev VIEW


    function getAllPlayersInfo() external view returns (address[] memory players, uint256[] memory eventIds, uint256[] memory outcomeIds, uint256[] memory betAmounts, uint256[] memory timestamps) {
        
        
    }

    function getAllBetsInEvent(uint256 _eventId) external view verifyEvent(_eventId) returns (address[] memory players, uint256[] memory outcomeIds, uint256[] memory betAmounts, uint256[] memory timestamps) {
       

    } 

    function getReverseOutcome(uint256 _eventId, uint256 _outcomeId) external view verifyEvent(_eventId) returns (uint256) {
        return reverseOutcomes[_eventId][_outcomeId];
    }

    function getAllUserBets(address user) external view returns (uint256[] memory eventIds, uint256[] memory outcomeIds, uint256[] memory betAmounts, uint256[] memory timestamps) {
        
    }

    function getEventOutcomeIds(uint256 _eventId) external view verifyEvent(_eventId) returns (uint256[] memory)  {
        uint256[] memory outcomeIds = new uint256[](eventInfo[_eventId].outcomeIds.length);
        for (uint256 i; i < eventInfo[_eventId].outcomeIds.length; i++) {
            outcomeIds[i] = reverseOutcomes[_eventId][i];
        }
        return outcomeIds;
    }


    /// @dev Player Functions

    /// TODO
    function placeBet(uint256 _eventId, uint256 _betAmount, uint256 _outcomeID, IBEP20 _token) external verifyEvent(_eventId) {
        require(contractActive, "Contract has been paused");
        require(allowedTokens[_token], "Token not recognised");
        require(eventInfo[_eventId].exists, "Event does not exist");
        require(eventInfo[_eventId].startTime <= block.timestamp, "Event has not started");
        require(eventInfo[_eventId].endTime >= block.timestamp, "Event has already finished");
        require(!eventInfo[_eventId].refundAllowed, "Cannot bet on this event");

        uint256 _contractId = eventOutcomeIds[_eventId][_outcomeID];
        require(eventOutcomeExists[_eventId][_outcomeID], "Outcome doesn't exist");
        if (playerInfo[_eventId][_msgSender()].inGame) {
            require(_contractId == playerInfo[_eventId][_msgSender()].outcome, "Trying to bet on a different outcome");
        } else {
            eventInfo[_eventId].totalNumOfPlayers += 1;
            playerInfo[_eventId][_msgSender()].outcome = _contractId;
        }

        if (!addedToAllPlayers[_msgSender()]) {
            allPlayers.push(_msgSender());
            addedToAllPlayers[_msgSender()] = true;
        }

        _token.safeTransferFrom(_msgSender(), address(this), _betAmount);

        bool processed = _processBet(_msgSender(), _eventId, _betAmount, _contractId, _token);
        require(processed);
        emit BetPlaced(_msgSender(), _betAmount, _outcomeID);
    }

    /// TODO
    function claimReward(uint256 _eventId) external verifyEvent(_eventId) returns (uint256[] memory) {
        require(playerInfo[_eventId][_msgSender()].inGame, "Player has not participated");
        require(!eventInfo[_eventId].refundAllowed, "Refunds are issued for this event");
        require(eventInfo[_eventId].outcomeSet, "Outcome for this event wasn't set yet");
        require(playerInfo[_eventId][_msgSender()].outcome == eventInfo[_eventId].realOutcome, "User didn't win");
        require(!playerInfo[_eventId][_msgSender()].winClaimed, "You have already claimed your win");

        uint256 share;
        uint256[] memory payableInToken = new uint256[](arrayOfEventTokens.length);
        for (uint256 i; i < playerInfo[_eventId][_msgSender()].betAmount.length; i ++) {
            share += playerInfo[_eventId][_msgSender()].betAmount[i] * eventFinances[_eventId][playerInfo[_eventId][_msgSender()].tokens[i]].finalPrice / 10**18;
            payableInToken[_getIndexOfToken(playerInfo[_eventId][_msgSender()].tokens[i])] += playerInfo[_eventId][_msgSender()].betAmount[i];
        }

        for (uint256 x; x < arrayOfEventTokens.length; x++) {
            payableInToken[x] += (eventFinances[_eventId][arrayOfEventTokens[x]].total - eventFinances[_eventId][arrayOfEventTokens[x]].totalForOutcome[eventInfo[_eventId].realOutcome]) * share / 10**18;
            arrayOfEventTokens[x].safeTransfer(_msgSender(), payableInToken[x]);
        }
        emit WinClaimed(_msgSender(), _eventId);
        return payableInToken;
    }

    /// TODO
    function claimRefund(uint256 _eventId) external verifyEvent(_eventId) {

        emit RefundClaimed(_msgSender(), _eventId);
    }

    /// @dev System Functions

    /// DONE
    function initializeGame(uint256[] memory _outcomeIds, uint256 _startTime, uint256 _endTime, address _creator, uint256 _oraculaFee, uint256 _creatorFee) external onlyOracula returns (uint256) {
        require(contractActive, "Contract has been paused");
        eventCounter ++;
        eventInfo[eventCounter].exists = true;
        eventInfo[eventCounter].startTime = _startTime;
        eventInfo[eventCounter].endTime = _endTime;
        eventInfo[eventCounter].creator = _creator;
        eventInfo[eventCounter].oraculaFee = _oraculaFee;
        eventInfo[eventCounter].creatorFee = _creatorFee;
        eventInfo[eventCounter].outcomeIds = new uint256[](_outcomeIds.length);
        for (uint256 i = 0; i < _outcomeIds.length; i++) {
            eventOutcomeIds[eventCounter][_outcomeIds[i]] = i;
            eventOutcomeExists[eventCounter][_outcomeIds[i]] = true;
            reverseOutcomes[eventCounter][i] = _outcomeIds[i];
        }
        emit EventCreated(eventCounter, _creator, _creatorFee, _oraculaFee);
        return eventCounter;
    }

    /// DONE
    function changeEventTime(uint256 _eventId, uint256 _startTime, uint256 _endTime) external onlyOracula {
        require(eventInfo[_eventId].exists, "Event does not exist");
        require(!eventInfo[_eventId].outcomeSet, "Outcome is already set");
        EventInfo storage _event = eventInfo[_eventId];
        if (_event.endTime < block.timestamp) {
            require(!_event.outcomeSet, "Event outcome has already been set");
        }
        _event.startTime = _startTime;
        _event.endTime = _endTime;
    }

    /// DONE
    function changeEventCreatorAddress(uint256 _eventId, address newCreator) external onlyOracula {
        require(eventInfo[_eventId].exists , "Event does not exist");
        require(!eventInfo[_eventId].outcomeSet, "Fees have been already distributed");
        eventInfo[_eventId].creator = newCreator;
    }

    /// DONE
    function changeEventFees(uint256 _eventId, uint256 _creatorFee, uint256 _oraculaFee) external onlyOwner {
        require(eventInfo[_eventId].exists , "Event does not exist");
        require(!eventInfo[_eventId].outcomeSet, "Fees have been already distributed");
        eventInfo[_eventId].oraculaFee = _oraculaFee;
        eventInfo[_eventId].creatorFee = _creatorFee;
    }

    /// TODO
    function setEventOutcome(uint256 _eventId, uint256 _realOutcome) external onlyOracula verifyEvent(_eventId) {
        require(eventInfo[_eventId].endTime < block.timestamp, "Event has not finished yet");
        require(!eventInfo[_eventId].outcomeSet, "Outcomes were set already");
        require(!eventInfo[_eventId].refundAllowed, "Refunds are issued for this event");
        require(eventOutcomeExists[_eventId][_realOutcome], "Outcome doesn't exist");
        uint256 contractId = eventOutcomeIds[_eventId][_realOutcome];
        uint256 totalInBets;
        for (uint256 i; i < arrayOfEventTokens.length; i ++) {
            eventFinances[_eventId][arrayOfEventTokens[i]].finalPrice = _getPriceOfAsset(address(arrayOfEventTokens[i]), 1*10**18);
            totalInBets += eventFinances[_eventId][arrayOfEventTokens[i]].finalPrice * eventFinances[_eventId][arrayOfEventTokens[i]].total;
        }

        eventInfo[_eventId].realOutcome = contractId;
        eventInfo[_eventId].outcomeSet = true;

        eventInfo[_eventId].power = 1 * 10**36 / totalInBets;
        eventInfo[_eventId].totalBets = totalInBets;

        if (eventInfo[_eventId].oraculaFee > 0 || eventInfo[_eventId].creatorFee > 0) {
            uint256 feeInTokens;
            uint256 feeSum = eventInfo[_eventId].oraculaFee + eventInfo[_eventId].creatorFee;
            for (uint256 x; x < arrayOfEventTokens.length; x++) {
                feeInTokens = eventFinances[_eventId][arrayOfEventTokens[x]].total - eventFinances[_eventId][arrayOfEventTokens[x]].totalForOutcome[contractId];
                if (eventInfo[_eventId].oraculaFee > 0) {
                    arrayOfEventTokens[x].safeTransfer(oraculaSystem, feeInTokens * eventInfo[_eventId].oraculaFee / feeSum);
                }
                if (eventInfo[_eventId].creatorFee > 0) {
                    arrayOfEventTokens[x].safeTransfer(eventInfo[_eventId].creator, feeInTokens * eventInfo[_eventId].creatorFee / feeSum);
                }
            }
        }

        emit EventFinished(_eventId, _realOutcome);
    }

    /// ??? 
    function setRefundStatus(uint256 _eventId, bool value) external onlyOracula verifyEvent(_eventId) {
        eventInfo[_eventId].refundAllowed = value;
    }

    /// @dev onlyOwner

    function addTokensToAllowList(IBEP20[] memory tokens) external onlyOwner {
        for (uint256 i; i < tokens.length; i++) {
            allowedTokens[tokens[i]] = true;
            arrayOfEventTokens.push(tokens[i]);
        }
    }

    function removeTokensFromAllowList(IBEP20[] memory tokens) external onlyOwner {
        for (uint256 i; i < tokens.length; i++) {
            allowedTokens[tokens[i]] = false;
            for (uint256 x = 0; x < arrayOfEventTokens.length; x++) {
                if (arrayOfEventTokens[x] == tokens[i]) {
                    for (uint256 z = x; z < arrayOfEventTokens.length - 1; z++) {
                        arrayOfEventTokens[z] = arrayOfEventTokens[z+1];
                    }
                    arrayOfEventTokens.pop();
                }
            }
        }
    }

    function changeOraculaAddress(address _newOracula) external onlyOwner {
        oraculaSystem = _newOracula;
    }

    function emergencyWithdraw(IBEP20 token) external onlyOwner {
        token.safeTransfer(owner(), token.balanceOf(address(this)));
    }

    function pauseContract(bool value) external onlyOwner {
        require(activeCouldBeChanged, "Contract has been permanently closed");
        contractActive = value;
    }

    /// TODO: Change function to allow for multiple tokens
    function emergencyStop() external onlyOwner {
        // if (activeCouldBeChanged) {
        //     contractActive = false;
        //     activeCouldBeChanged = false;
        // } 
        // require(!contractActive, "Contract is still active, idk how");
        // uint256 _emergencyStopCount = emergencyStopCount;
        // uint256 gasUsed;
        // uint256 gasLeft = gasleft();
        // for (uint256 i = emergencyStopCount; gasUsed < 5000000 && i < allPlayers.length; i ++) {
        //     uint256[] memory refundPerToken = new uint256[](arrayOfEventTokens.length);
        //     for (uint256 x; x < eventInfo.length; x++) {
        //         if (playerInfo[x][allPlayers[i]].inGame && playerInfo[x][allPlayers[i]].betAmount.length > 0 && !playerInfo[x][allPlayers[i]].winClaimed) {
        //             refundPerToken[_getIndexOfToken(eventToken[x])] = refundPerToken[_getIndexOfToken(eventToken[x])] + playerInfo[x][allPlayers[i]].totalBet;
        //             playerInfo[x][allPlayers[i]].inGame = false;
        //         }
        //     }
        //     for (uint256 y; y < refundPerToken.length; y++) {
        //         if (refundPerToken[y] > 0) {
        //             IBEP20(arrayOfEventTokens[y]).safeTransfer(allPlayers[i], refundPerToken[y]);
        //         }
        //     }
        //     gasUsed += gasLeft - gasleft();
        //     gasLeft = gasleft();
        //     _emergencyStopCount ++;
        // }
        // emergencyStopCount = _emergencyStopCount;
    }

    /// @dev Internal 

    function _processBet(address user, uint256 _eventId, uint256 _betAmount, uint256 _contractId, IBEP20 _token) internal returns (bool) {
        PlayerInfo storage _player = playerInfo[_eventId][user];
        EventInfo storage _event = eventInfo[_eventId];
        EventFinances storage _eventFinances = eventFinances[_eventId][_token];

        _eventFinances.outcomeIds.push(_contractId);
        _eventFinances.betAmounts.push(_betAmount);
        _eventFinances.totalForOutcome[_contractId] += _betAmount;

        _event.totalNumOfBets ++;

        _player.inGame = true;
        _player.tokens.push(_token);
        _player.betAmount.push(_betAmount);
        _player.timestamp.push(block.timestamp);

        _eventFinances.outcomeIds.push(_contractId);
        _eventFinances.betAmounts.push(_betAmount);
        _eventFinances.totalForOutcome[_contractId] += _betAmount;
        _eventFinances.total += _betAmount;

        return true;
    }

    function _getIndexOfToken(IBEP20 token) internal view returns (uint256 i) {
        for (i; i < arrayOfEventTokens.length; i++) {
            if (token == arrayOfEventTokens[i]) {
                return i;
            }
        }
    }


    IUniswapV2Router02 private router =
        IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);   
    IBEP20 BUSD = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);


    /// @dev in BUSD
    function _getPriceOfAsset(address asset, uint256 tokenAmount) public view returns (uint256) {
        // address pairAddress = IUniswapV2Factory(router.factory()).getPair(address(BUSD), asset);

        // IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        // (uint256 Res0, uint256 Res1, ) = pair.getReserves();

        // if (pair.token0() == address(BUSD)) {
        //     return ((tokenAmount * Res0) / Res1); // return amount of token0 needed to buy token1
        // } else {
        //     return ((tokenAmount * Res1) / Res0); // return amount of token0 needed to buy token1
        // }

        return 10**18;
    }

}