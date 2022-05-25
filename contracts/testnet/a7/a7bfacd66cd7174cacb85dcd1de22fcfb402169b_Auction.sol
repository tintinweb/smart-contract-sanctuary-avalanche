/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-24
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;

library SafeMathLib {
  function times(uint a, uint b) public pure returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b, 'Overflow detected');
    return c;
  }

  function minus(uint a, uint b) public pure returns (uint) {
    require(b <= a, 'Underflow detected');
    return a - b;
  }

  function plus(uint a, uint b) public pure returns (uint) {
    uint c = a + b;
    require(c>=a && c>=b, 'Overflow detected');
    return c;
  }

}

contract Token {
    using SafeMathLib for uint;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    mapping (uint => FrozenTokens) public frozenTokensMap;

    event Transfer(address indexed sender, address indexed receiver, uint value);
    event Approval(address approver, address spender, uint value);
    event TokensFrozen(address indexed freezer, uint amount, uint id, uint lengthFreezeDays);
    event TokensUnfrozen(address indexed unfreezer, uint amount, uint id);
    event TokensBurned(address burner, uint amount);
    event TokensMinted(address recipient, uint amount);
    event BankUpdated(address oldBank, address newBank);

    uint8 constant public decimals = 18;
    string constant public symbol = "FACT";
    string constant public name = "FactoryDAO Token";
    uint public totalSupply;
    uint numFrozenStructs;
    address public bank;

    struct FrozenTokens {
        uint id;
        uint dateFrozen;
        uint lengthFreezeDays;
        uint amount;
        bool frozen;
        address owner;
    }

    // simple initialization, giving complete token supply to one address
    constructor(address _bank) {
        bank = _bank;
        require(bank != address(0), 'Must initialize with nonzero address');
        uint totalInitialBalance = 1e9 * 1 ether;
//        uint totalInitialBalance = 0;
        balances[bank] = totalInitialBalance;
        totalSupply = totalInitialBalance;
        emit Transfer(address(0), bank, totalInitialBalance);
    }

    modifier bankOnly() {
        require (msg.sender == bank, 'Only bank address may call this');
        _;
    }

    function setBank(address newBank) public bankOnly {
        address oldBank = bank;
        bank = newBank;
        emit BankUpdated(oldBank, newBank);
    }

    // freeze tokens for a certain number of days
    function freeze(uint amount, uint freezeDays) public {
        require(amount > 0, 'Cannot freeze 0 tokens');
        // move tokens into this contract's address from sender
        balances[msg.sender] = balances[msg.sender].minus(amount);
        balances[address(this)] = balances[address(this)].plus(amount);
        numFrozenStructs = numFrozenStructs.plus(1);
        frozenTokensMap[numFrozenStructs] = FrozenTokens(numFrozenStructs, block.timestamp, freezeDays, amount, true, msg.sender);
        emit Transfer(msg.sender, address(this), amount);
        emit TokensFrozen(msg.sender, amount, numFrozenStructs, freezeDays);
    }

    // unfreeze frozen tokens
    function unFreeze(uint id) public {
        FrozenTokens storage f = frozenTokensMap[id];
        require(f.dateFrozen + (f.lengthFreezeDays * 1 days) < block.timestamp, 'May not unfreeze until freeze time is up');
        require(f.frozen, 'Can only unfreeze frozen tokens');
        f.frozen = false;
        // move tokens back into owner's address from this contract's address
        balances[f.owner] = balances[f.owner].plus(f.amount);
        balances[address(this)] = balances[address(this)].minus(f.amount);
        emit Transfer(address(this), msg.sender, f.amount);
        emit TokensUnfrozen(f.owner, f.amount, id);
    }

    // burn tokens, taking them out of supply
    function burn(uint amount) public {
        balances[msg.sender] = balances[msg.sender].minus(amount);
        totalSupply = totalSupply.minus(amount);
        emit Transfer(msg.sender, address(0), amount);
        emit TokensBurned(msg.sender, amount);
    }

    function mint(address recipient, uint amount) public bankOnly {
        uint totalAmount = amount * 1 ether;
        balances[recipient] = balances[recipient].plus(totalAmount);
        totalSupply = totalSupply.plus(totalAmount);
        emit Transfer(address(0), recipient, totalAmount);
        emit TokensMinted(recipient, totalAmount);
    }

    // burn tokens for someone else, subject to approval
    function burnFor(address burned, uint amount) public {
        uint currentAllowance = allowed[burned][msg.sender];

        // deduct
        balances[burned] = balances[burned].minus(amount);

        // adjust allowance
        allowed[burned][msg.sender] = currentAllowance.minus(amount);

        totalSupply = totalSupply.minus(amount);

        emit Transfer(burned, address(0), amount);
        emit TokensBurned(burned, amount);
    }

    // transfer tokens
    function transfer(address to, uint value) public returns (bool success)
    {
        if (to == address(0)) {
            burn(value);
        } else {
            // deduct
            balances[msg.sender] = balances[msg.sender].minus(value);
            // add
            balances[to] = balances[to].plus(value);

            emit Transfer(msg.sender, to, value);
        }
        return true;
    }

    // transfer someone else's tokens, subject to approval
    function transferFrom(address from, address to, uint value) public returns (bool success)
    {
        if (to == address(0)) {
            burnFor(from, value);
        } else {
            uint currentAllowance = allowed[from][msg.sender];

            // deduct
            balances[from] = balances[from].minus(value);

            // add
            balances[to] = balances[to].plus(value);

            // adjust allowance
            allowed[from][msg.sender] = currentAllowance.minus(value);

            emit Transfer(from, to, value);
        }
        return true;
    }

    // retrieve the balance of address
    function balanceOf(address owner) public view returns (uint balance) {
        return balances[owner];
    }

    // approve another address to transfer a specific amount of tokens
    function approve(address spender, uint value) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    // incrementally increase approval, see https://github.com/ethereum/EIPs/issues/738
    function increaseApproval(address spender, uint value) public returns (bool success) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].plus(value);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    // incrementally decrease approval, see https://github.com/ethereum/EIPs/issues/738
    function decreaseApproval(address spender, uint decreaseValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][spender];
        // allow decreasing too much, to prevent griefing via front-running
        if (decreaseValue >= oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.minus(decreaseValue);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    // retrieve allowance for a given owner, spender pair of addresses
    function allowance(address owner, address spender) public view returns (uint remaining) {
        return allowed[owner][spender];
    }

    function numCoinsFrozen() public view returns (uint) {
        return balances[address(this)];
    }}

interface IUniswapRouter {

    event LiquidityAdded(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline);

    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
//        virtual
//        override
        payable
//        ensure(deadline)
        returns (uint[] memory amounts);
//    {
//        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
//        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);
//        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
//        IWETH(WETH).deposit{value: amounts[0]}();
//        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
//        _swap(amounts, path, to);
//    }

}


/**
 * @title Auction
 */

contract Auction {
    using SafeMathLib for uint;

    struct Tranche {
        uint blockIssued;
        uint weiPerToken;
        uint totalTokens;
        uint currentTokens;
    }

    address public management;
    uint256 public decayPerBlock;
    uint256 public lastTokensPerWei;
    uint256 public trancheNumber = 1;
    uint256 public totalTokensOffered;
    uint256 public totalTokensSold = 0;

    uint256 public initialPrice = 0;
    uint256 public initialTrancheSize = 0;
    uint256 public minimumPrice = 0;
    uint256 public startBlock = 0;

    bytes32 public siteHash;

    address payable public safeAddress;
    Token public token;
    IUniswapRouter public uniswap;
    Tranche public currentTranche;

    event PurchaseOccurred(address purchaser, uint weiSpent, uint tokensAcquired, uint tokensLeftInTranche, uint weiReturned, uint trancheNumber, uint timestamp);
    event LiquidityPushed(uint amountToken, uint amountETH, uint liquidity);

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Auction: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier managementOnly() {
        require (msg.sender == management, 'Only management may call this');
        _;
    }

    constructor(address mgmt,
                address tokenAddr,
                address uniswapRouter,
                uint auctionStartBlock,
                uint tokensForSale,
                uint firstTranchePricePerToken,
                uint firstTrancheSize,
                uint initialDecay,
                uint minPrice,
                address payable safeAddr) {
        management = mgmt;
        token = Token(tokenAddr);
        uniswap = IUniswapRouter(uniswapRouter);
        startBlock = auctionStartBlock > 0 ? auctionStartBlock : block.number;
        totalTokensOffered = tokensForSale;
        initialPrice = firstTranchePricePerToken;
        initialTrancheSize = firstTrancheSize;
        currentTranche = Tranche(startBlock, firstTranchePricePerToken, firstTrancheSize, firstTrancheSize);
        decayPerBlock = initialDecay;
        safeAddress = safeAddr;
        minimumPrice = minPrice;
    }

    /**
     * @dev default function
     * gas ~
     */
    receive() external payable {
        buy(currentTranche.weiPerToken);
    }

    function withdrawTokens() public managementOnly {
        uint balance = token.balanceOf(address(this));
        token.transfer(management, balance);
    }

//    function withdrawEther() public {
//        uint balance = address(this).balance;
//        safeAddress.transfer(balance);
//    }

    function setSiteHash(bytes32 newHash) public managementOnly {
        siteHash = newHash;
    }

    function pushLiquidity() public managementOnly {
        uint tokenBalance = token.balanceOf(address(this));
        uint minToken = tokenBalance / 2;
        uint ethBalance = address(this).balance;
        uint deadline = block.timestamp + 1 hours;
        token.approve(address(uniswap), tokenBalance);
        // this will take all the eth and refund excess tokens
//        (uint amountToken, uint amountETH, uint liquidity) = uniswap.addLiquidityETH{value: ethBalance}(address(token), tokenBalance, tokenBalance, ethBalance, safeAddress, deadline);
        (uint amountToken, uint amountETH, uint liquidity) = uniswap.addLiquidityAVAX{value: ethBalance}(address(token), tokenBalance, minToken, ethBalance, safeAddress, deadline);
        emit LiquidityPushed(amountToken, amountETH, liquidity);
    }

    function getBuyPrice() public view returns (uint) {
        if (block.number < currentTranche.blockIssued) {
            return 0;
        }
        // linear time decay
        uint distanceBlocks = block.number.minus(currentTranche.blockIssued);
        uint decay = decayPerBlock.times(distanceBlocks);
        uint proposedPrice;
        if (currentTranche.weiPerToken < decay.plus(minimumPrice)) {
            proposedPrice = minimumPrice;
        } else {
            proposedPrice = currentTranche.weiPerToken.minus(decay);
        }
        return proposedPrice;
    }

    /**
     * @dev Buy tokens
     * gas ~
     */
    function buy(uint maxPrice) public payable lock {
        require(msg.value > 0, 'Auction: must send ether to buy');
        require(block.number >= startBlock, 'Auction: not started yet');
        // buyPrice = wei / 1e18 tokens
        uint weiPerToken = getBuyPrice();

        require(weiPerToken <= maxPrice, 'Auction: price too high');
        // buyAmount = wei * tokens / wei = tokens
        uint buyAmountTokens = (msg.value * 1 ether) / weiPerToken;
        uint leftOverTokens = 0;
        uint weiReturned = 0;
        uint trancheNumReported = trancheNumber;

        // if they bought more than the tranche has...
        if (buyAmountTokens >= currentTranche.currentTokens) {
            // compute the excess amount of tokens
            uint excessTokens = buyAmountTokens - currentTranche.currentTokens;
            // weiReturned / msg.value = excessTokens / buyAmountTokens
            weiReturned = msg.value.times(excessTokens) / buyAmountTokens;
            // send the excess ether back
            // re-entrance blocked by the lock modifier
            msg.sender.transfer(weiReturned);
            // now they are only buying the remaining
            buyAmountTokens = currentTranche.currentTokens;

            // double the tokens offered
            uint nextTrancheTokens = currentTranche.totalTokens.times(2);
            uint tokensLeftInOffering = totalTokensOffered.minus(totalTokensSold).minus(buyAmountTokens);

            // if we are not offering enough tokens to cover the next tranche doubling, this is the last tranche
            if (nextTrancheTokens > tokensLeftInOffering) {
                nextTrancheTokens = tokensLeftInOffering;
            }

            // double the price per token
            currentTranche.weiPerToken = weiPerToken.times(2);

            // set the new tranche token amounts
            currentTranche.totalTokens = nextTrancheTokens;
            currentTranche.currentTokens = currentTranche.totalTokens;

            // double the decay per block and reset the block issued
            currentTranche.blockIssued = block.number;
            decayPerBlock = decayPerBlock.times(2);

            // increment tranche index
            trancheNumber = trancheNumber.plus(1);

        } else {
            currentTranche.currentTokens = currentTranche.currentTokens.minus(buyAmountTokens);
            leftOverTokens = currentTranche.currentTokens;
        }

        // send the tokens! re-entrance not possible here because of Token design, but will be possible with ERC-777
        token.transfer(msg.sender, buyAmountTokens);

        // bookkeeping: count the tokens sold
        totalTokensSold = totalTokensSold.plus(buyAmountTokens);
        emit PurchaseOccurred(msg.sender, msg.value.minus(weiReturned), buyAmountTokens, leftOverTokens, weiReturned, trancheNumReported, block.timestamp);
    }

}