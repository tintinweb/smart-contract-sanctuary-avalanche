/**
 *Submitted for verification at snowtrace.io on 2022-04-27
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// File: contracts/Auth.sol


pragma solidity ^0.8.11;

abstract contract Auth {
  address internal owner;
  mapping(address => bool) internal authorizations;

  constructor(address _owner) {
    owner = _owner;
    authorizations[_owner] = true;
  }

  /**
   * Function modifier to require caller to be contract owner
   */
  modifier onlyOwner() {
    require(isOwner(msg.sender), '!OWNER');
    _;
  }

  /**
   * Function modifier to require caller to be authorized
   */
  modifier authorized() {
    require(isAuthorized(msg.sender), '!AUTHORIZED');
    _;
  }

  /**
   * Authorize address. Owner only
   */
  function authorize(address adr) public onlyOwner {
    authorizations[adr] = true;
  }

  /**
   * Remove address' authorization. Owner only
   */
  function unauthorize(address adr) public onlyOwner {
    authorizations[adr] = false;
  }

  /**
   * Check if address is owner
   */
  function isOwner(address account) public view returns (bool) {
    return account == owner;
  }

  /**
   * Return address' authorization status
   */
  function isAuthorized(address adr) public view returns (bool) {
    return authorizations[adr];
  }

  /**
   * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
   */
  function transferOwnership(address payable adr) public onlyOwner {
    owner = adr;
    authorizations[adr] = true;
    emit OwnershipTransferred(adr);
  }

  event OwnershipTransferred(address owner);
}
// File: contracts/interfaces/IDEXRouter.sol


pragma solidity ^0.8.11;

interface IDEXRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

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

    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
// File: contracts/interfaces/IJoePair.sol


pragma solidity ^0.8.11;

interface IJoePair {
    
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}
// File: contracts/interfaces/IEtherstonesRewardManagerv2.sol


pragma solidity ^0.8.11;
pragma experimental ABIEncoderV2;

interface IEtherstonesRewardManagerv2 {
    function getOwnedNodeIDs(address owner) external view returns (uint256[] memory);
    function unpackEtherstoneByID(uint256 id) external view returns (string memory, uint256, uint256, uint256, uint256, uint256, uint256, address);
}
// File: contracts/ETHSLottery.sol


pragma solidity ^0.8.11;






contract ETHSLottery is Auth {

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    IEtherstonesRewardManagerv2 manager;
    IERC20 eths;

    mapping(address => uint256) public cooldowns;
    uint256 cooldownTimer = 1 days;
    uint256 lockedPercentage = 5;
    uint256 lockedPercentageDenominator = 100;
    uint256 private incrementedNumber;

    uint256 houseEdge = 45;
    IJoePair pair;
    IDEXRouter router;

    uint256 jackpotOdds = 500;
    uint256 jackpotMultiplier = 10;

    uint256 commission = 20;

    bool jackpotEnabled = true;

    event LotteryEvent(address player, uint256 avaxAmount, uint256 ethsAmount);

    constructor(address token, address _manager, address _pair, address _router) Auth(msg.sender) {
        eths = IERC20(token);
        manager = IEtherstonesRewardManagerv2(_manager);
        pair = IJoePair(_pair);
        router = IDEXRouter(_router);
        eths.approve(_router, type(uint256).max);
    }

    function enterLottery() external payable {
        require(msg.sender == tx.origin, "No contracts");
        require(cooldowns[msg.sender] + cooldownTimer <= block.timestamp, "On cooldown");
        cooldowns[msg.sender] = block.timestamp;

        (uint256 totalLocked, uint256 lotteryEntryPrice) = getTotalLockedAndEntryPrice(msg.sender);
        require(msg.value >= lotteryEntryPrice, "Entry fee not paid");
        require(totalLocked > 0, "Must have some ETHS locked");

        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = address(eths);
        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{value: (msg.value*(100-commission))/100}(
            0, 
            path, 
            address(this),
            block.timestamp
        );

        uint256 maxWinnings = (totalLocked * lockedPercentage)/lockedPercentageDenominator;
        uint256 randomAmount = random(msg.sender, maxWinnings);
        incrementedNumber += randomAmount;

        uint256 winnings;
        if(jackpotEnabled && isJackpotWinner(msg.sender)) {
            winnings = maxWinnings*jackpotMultiplier;
        } else {
            winnings = randomAmount;
        }
        eths.transfer(msg.sender, winnings);

        emit LotteryEvent(msg.sender, lotteryEntryPrice, winnings);
    }

    function isJackpotWinner(address sender) private returns (bool) {
        return ((incrementedNumber + random(sender, incrementedNumber)) % jackpotOdds) == 0;
    }

    function getTotalLockedAndEntryPrice(address user) public view returns (uint256, uint256) {
        uint256[] memory nodes = manager.getOwnedNodeIDs(user);
        uint256 totalLocked = 0;
        uint256 len = nodes.length;
        for(uint i = 0; i < len; i++) {
            (string memory _s,uint _i,uint _l,uint locked,uint _n,uint _t, uint _tc,address _a) = manager.unpackEtherstoneByID(nodes[i]);
            totalLocked+=locked;
        }
        uint256 avaxPerETHS = getAVAXPerETHS();
        return (totalLocked, (((((totalLocked*avaxPerETHS)/1e18)*houseEdge)/100)*lockedPercentage)/lockedPercentageDenominator);
    }

    function random(address sender, uint256 limit) private view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(sender)))) / (block.timestamp)) +
            block.number + incrementedNumber
        )));
        return seed % limit;
    } 

    function getAVAXPerETHS() private view returns (uint256) {
        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = pair.getReserves();
        uint256 _ETHSReserve;
        uint256 _AVAXReserve;
        address _token0 = pair.token0();
        if(_token0 == address(eths)) {
            _ETHSReserve = _reserve0;
            _AVAXReserve = _reserve1;
        } else {
            _ETHSReserve = _reserve1;
            _AVAXReserve = _reserve0;
        }
        require(_ETHSReserve > 0, "divison by zero error");
        return (_AVAXReserve * 1e18) / _ETHSReserve;
    }

    function getLotteryCooldown() public view returns (uint256) {
        return cooldowns[msg.sender] + cooldownTimer;
    }

    function setCooldown(uint256 time) external onlyOwner {
        cooldownTimer = time;
    }

    function setLotteryPercentages(uint256 percent, uint256 denom) external onlyOwner {
        lockedPercentage = percent;
        lockedPercentageDenominator = denom;
    }

    function setHouseEdge(uint256 edge) external onlyOwner {
        houseEdge = edge;
    }

    function setJackpotSettings(uint256 odds, uint256 multiplier) external onlyOwner {
        jackpotOdds = odds;
        jackpotMultiplier = multiplier;
    }

    function setCommission(uint256 _commission) external onlyOwner {
        require(_commission >= 0 && _commission <= 100, "Invalid commission");
        commission = _commission;
    }

    function setJackpotEnabled(bool decision) external onlyOwner {
        jackpotEnabled = decision;
    }

    function setContracts(address _token, address _manager, address _pair, address _router) external onlyOwner {
        eths = IERC20(_token);
        manager = IEtherstonesRewardManagerv2(_manager);
        pair = IJoePair(_pair);
        router = IDEXRouter(_router);
    }

    function burn(uint256 amount) external onlyOwner {
        eths.transfer(DEAD, amount);
    }

    function sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}