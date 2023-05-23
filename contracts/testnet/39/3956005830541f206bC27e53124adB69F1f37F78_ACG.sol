// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * Import the ERC20 contract, which implements the standard ERC20 token interface
 * for managing and transferring tokens on the Ethereum/BSC blockchain.
 */
import "./contracts/token/ERC20/ERC20.sol";
/*
 * Import the Ownable contract, which provides basic access control functions and allows the
 * contract owner to transfer ownership to another address.
 */
import "./contracts/access/Ownable.sol";
/*
 * Import the SafeMath library, which provides safe arithmetic functions that prevent overflow
 * and underflow errors when working with integers.
 */
import "./contracts/utils/math/SafeMath.sol";
/*
 * Import the Address library, which provides utility functions for working with Ethereum addresses,
 * including checking if an address is a contract or not.
 */
import "./contracts/utils/Address.sol";
/*
 * Import the interface for the Uniswap V2 / Pancakeswap V2 Factory contract, which provides functions for
 * creating and managing pairs of tokens on the Uniswap V2 / Pancakeswap V2 decentralized exchange.
 */
import "./contracts/interfaces/IUniswapV2Factory.sol";
/*
 * Import the interface for the Uniswap V2 / Pancakeswap V2 Pair contract, which represents a pair of tokens
 * in the Uniswap V2 / Pancakeswap V2 decentralized exchange.
 */
import "./contracts/interfaces/IUniswapV2Pair.sol";
/*
 * Import the interface for the Uniswap V2 / Pancakeswap V2 Router contract, which provides functions for
 * swapping tokens on the Uniswap V2 / Pancakeswap V2 decentralized exchange.
 */
import "./contracts/interfaces/IUniswapV2Router02.sol";

/// @custom:security-contact [email protected]
contract ACG is ERC20, Ownable {
    // Use the SafeMath library to perform arithmetic operations with uint256 variables safely.
    using SafeMath for uint256;
    // Use the Address library to interact with Ethereum addresses.
    using Address for address;

    // Balances of token holders.
    mapping(address => uint256) private _balances;
    // Allowances granted by token holders to other addresses.
    mapping(address => mapping(address => uint256)) private _allowances;

    // A mapping of addresses that are excluded or included in fee calculations.
    // Fees are not charged to excluded addresses.
    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => uint256) public botLastTransferBlock;
    mapping(address => uint256) public botSellCount;
    uint256 public _maxBotSellCount = 5;
    uint256 public _botSellTimeBlockLimit = 100; // 1block/3sec = 5 minitues
    bool public antiBotEnabled = true;

    // Define the total number of tokens that can be created and set it to 1,000,000,000 multiplied by 10^18 (to account for decimal places).
    // This is the total supply of tokens that will ever exist in the system.
    uint256 private _totalSupply = 1000000000 * 10 ** 18;
    // Set a maximum value that a variable can hold. This is done to ensure that the token supply remains within a certain limit.
    uint256 private constant MAX_TOKEN_SUPPLY = ~uint256(0);
    // Calculate the largest possible number of tokens that can be minted by the smart contract, which is evenly divisible by the total supply of tokens.
    // This ensures that the total number of tokens remains consistent and makes it easier to manage token balances and transactions.
    uint256 private _maxMintableSupply = (MAX_TOKEN_SUPPLY -
        (MAX_TOKEN_SUPPLY % _totalSupply));
    // The maximum amount of tokens that can be transferred in a single transaction.
    uint256 public _maxTxAmount = 150000000 * 10 ** 18; // 15% of the total supply
    // The whale amount of tokens that is being swapped in a single transaction.
    uint256 public _penaltyTxAmount = 10000000 * 10 ** 18; // 1% of the total supply

    // The total amount of tokens that have been charged as Buy & Sell orders transaction fees.
    uint256 public _totalFeesCharged;

    // The minimum balance of tokens that must be held in the contract before it can swap tokens and collect transaction fees.
    // Once the balance of tokens held in the contract exceeds the _swapThresholdLimit, the contract can swap tokens for the underlying asset and collect fees.
    uint256 private _swapThresholdLimit = 500000 * 10 ** 18;

    // The name of the token.
    string private _name = "Addictive Crypto Games";
    // The symbol of the token.
    string private _symbol = "ACG";
    // The number of decimal places for the token.
    uint8 private _decimals = 18;

    // The address of the PancakeSwap Router contract.
    IUniswapV2Router02 public uniswapV2Router;
    // The address of the token pair contract.
    address public uniswapV2Pair;

    // A boolean flag to indicate whether the contract is currently swapping and adding/getting liquidity/fees.
    bool private _isSwappingAndGettingFees;
    // Swap/get liquidity/fees Enabled/Disabled
    bool public _isSwapAndGetFeesEnabled = true;

    // Boolean flag to track if fees are being set
    bool private _feesAreBeingSet;

    // The percentage fee charged for operations.
    uint256 public _operationFee = 2;
    uint256 private _previousOperationFee = _operationFee;

    // The percentage fee charged for marketing.
    uint256 public _marketingFee = 3;
    uint256 private _previousMarketingFee = _marketingFee;

    // The percentage fee charged for pools & leaderboards.
    uint256 public _poolsLeaderboardFee = 5;
    uint256 private _previousPoolsLeaderboardsFee = _poolsLeaderboardFee;

    // The percentage fee charged for community.
    uint256 public _communityFee = 1;
    uint256 private _previousCommunityFee = _communityFee;

    // The percentage fee charged for treasury one.
    uint256 public _treasuryOneFee = 2;
    uint256 private _previousTreasuryOneFee = _treasuryOneFee;

    // The percentage fee charged for treasury two.
    uint256 public _treasuryTwoFee = 2;
    uint256 private _previousTreasuryTwoFee = _treasuryTwoFee;

    // The percentage fee charged for liquidity.
    uint256 public _liquidityFee = 5;
    uint256 private _previousLiquidityFee = _liquidityFee;

    // The percentage fee charged for whales penalty.
    uint256 public _penaltyFee = 10;
    uint256 private _previousPenaltyFee = _penaltyFee;

    /**
     * The total fees required for a Buy or Sell transaction,
     * including development, marketing, game, and liquidity fees
     */
    uint256 public totalRequiredFees =
        _operationFee
            .add(_marketingFee)
            .add(_poolsLeaderboardFee)
            .add(_communityFee)
            .add(_treasuryOneFee)
            .add(_treasuryTwoFee)
            .add(_liquidityFee)
            .add(_penaltyFee);

    /**
     * The total fees required for a Buy orders.
     */
    uint256 public totalRequiredBuyFees =
        _operationFee.add(_marketingFee).add(_liquidityFee);

    /**
     * The total fees required for a sell orders.
     */
    uint256 public totalRequiredSellFees =
        _poolsLeaderboardFee.add(_communityFee).add(_treasuryOneFee).add(
            _treasuryTwoFee
        );

    // The total ERC20 fees charged for Buy & Sell.
    uint256 public totalERC20Fees = totalRequiredFees.sub(_liquidityFee);

    // Addresses of the wallets to receive the respective fees
    address public operationWallet = 0x0b8f1E27d13D17deC59cf263840577b946d51cc6;
    address public marketingWallet = 0x0b8f1E27d13D17deC59cf263840577b946d51cc6;
    address public poolsLeaderboardWallet =
        0x0b8f1E27d13D17deC59cf263840577b946d51cc6;
    address public communityWallet = 0x0b8f1E27d13D17deC59cf263840577b946d51cc6;
    address public treasuryOneWallet =
        0x0b8f1E27d13D17deC59cf263840577b946d51cc6;
    address public treasuryTwoWallet =
        0x0b8f1E27d13D17deC59cf263840577b946d51cc6;
    address public penaltyWallet = 0x0b8f1E27d13D17deC59cf263840577b946d51cc6;

    // Address of the ERC20 token to receive the fees in (e.g., BUSD, USDT)
    address public erc20TokenFeeAddress;

    // Modifier to prevent swapping and adding liquidity simultaneously
    modifier lockTheSwap() {
        require(
            !_isSwappingAndGettingFees,
            "ACG: Swap and liquify in progress"
        );
        _isSwappingAndGettingFees = true;
        _;
        _isSwappingAndGettingFees = false;
    }

    // Modifier to ensure that fees are not currently being set
    modifier feesNotBeingSet() {
        // Check that fees are not currently being set
        require(!_feesAreBeingSet, "ACG: Fees are being set.");
        // Set the flag to indicate that fees are being set
        _feesAreBeingSet = true;
        // Execute the function
        _;
        // Reset the flag to indicate that fees are no longer being set
        _feesAreBeingSet = false;
    }

    // Events to track swap and liquify enablement, and swap and liquify activity
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    event SwapAndGetFees(
        uint256 contractTokenBalance,
        uint256 newBalance,
        uint256 availableAmount
    );

    /**
     * @dev Constructor function to initialize the token and its initial state
     */
    constructor() ERC20(_name, _symbol) {
        // Initialize balances
        _balances[_msgSender()] = _maxMintableSupply;

        // Set up the pancake router and create a new pair for the token and WAVAX(WBNB)
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x688d21b0B8Dc35971AF58cFF1F7Bf65639937860
        );
        // Create a pancake pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WAVAX());

        uniswapV2Router = _uniswapV2Router;

        // Set the token used for fees to BUSD
        erc20TokenFeeAddress = address(
            0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7
        );

        // Exclude the owner and this contract from fees
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // Emit a transfer event to show the initial supply has been transferred to the contract deployer
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    // Get the name of the token
    function name() public view override returns (string memory) {
        return _name;
    }

    // Get the symbol of the token
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    // Get the number of decimal places used by the token
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    // Get the total supply of the token
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    // Get the balance of a specific account
    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_balances[account]);
    }

    // Fallback function to receive ETH
    receive() external payable {}

    /* overrides */

    /**
     * @dev Approves the given address to spend the specified amount of tokens on behalf of the owner.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param amount The amount of tokens to be spent.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        require(owner != address(0), "ACG: approve from the zero address");
        require(spender != address(0), "ACG: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Transfer amount of tokens from the caller's account to recipient.
     * @param recipient The address of the recipient.
     * @param amount The amount of tokens to transfer.
     * @return A boolean value indicating whether the transfer was successful or not.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Returns the amount of tokens that the spender is allowed to transfer from owner.
     * @param owner The address of the account holding the tokens.
     * @param spender The address of the account allowed to spend the tokens.
     * @return The number of tokens that spender is allowed to spend on behalf of owner.
     */
    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of the sender.
     * @param spender The address that will be allowed to spend the tokens.
     * @param amount The amount of tokens to be spent.
     * @return A boolean value indicating whether the approval was successful or not.
     */
    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev Transfers amount of tokens from the sender account to the recipient account,
     * and then reduces the allowance granted to spender by the caller for sender's tokens
     * by the same amount.
     * @param sender The address to transfer tokens from.
     * @param recipient The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     * @return A boolean value indicating whether the transfer was successful or not.
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ACG: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Increase the allowance granted to a spender to spend the caller's tokens.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     * @return A boolean value indicating whether the increase was successful or not.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public override returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Decreases the allowance granted to the spender by the caller's account by subtractedValue.
     * If the result is negative, it sets the allowance to zero instead.
     * Emits an {Approval} event.
     *
     * Requirements:
     * - spender cannot be the zero address.
     * - If the allowance is not enough, the transaction will revert with an "ERC20: decreased allowance below zero" error message.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     * @return A boolean value indicating whether the decrease was successful or not.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public override returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ACG: decreased allowance below zero"
            )
        );
        return true;
    }

    // Returns the contract's BNB balance
    function getBNBBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Returns the contract's balance of a specific ERC20 token (e.g. BUSD, USDT, etc.)
    function getErc20TokenFeeBalance() public view returns (uint256) {
        return IERC20(erc20TokenFeeAddress).balanceOf(address(this));
    }

    // Returns the contract's balance of a specific ERC20 token (specified by its address)
    function getErc20TokensBalance(
        address _token
    ) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    /**
     * @dev Sets the address of the Uniswap router and creates a new pair for the token and WAVAX if it does not already exist.
     * @param newRouter The address of the new Uniswap router.
     */
    function setSwapRouter(address newRouter) external onlyOwner {
        require(newRouter != address(0), "ACG: Invalid router address");
        IUniswapV2Factory factory = IUniswapV2Factory(newRouter);
        address wethAddress = IUniswapV2Router02(newRouter).WAVAX();

        // Check if a pair already exists for this token and WAVAX on the new router
        address pairAddress = factory.getPair(address(this), wethAddress);
        if (pairAddress == address(0)) {
            // If no pair exists, create a new one
            pairAddress = factory.createPair(address(this), wethAddress);
        }

        // Update the router and pair addresses
        uniswapV2Router = IUniswapV2Router02(newRouter);
        uniswapV2Pair = pairAddress;
    }

    /**
     * @dev Sets the new swap threshold limit.
     * @param _newLimit The new swap threshold limit to set.
     */
    function setSwapThresholdLimit(uint256 _newLimit) external onlyOwner {
        _swapThresholdLimit = _newLimit;
    }

    /**
     * @dev Sets the new penalty tx amount.
     * @param _newLimit The new swap threshold limit to set.
     */
    function setPenaltyTxAmount(uint256 _newLimit) external onlyOwner {
        _penaltyTxAmount = _newLimit;
    }

    /**
     * @dev Sets the address of the ERC-20 token to be used as the fee.
     * @param newToken The new address of the ERC-20 token to be used as the fee.
     */
    function setErc20TokenAddress(address newToken) external onlyOwner {
        require(newToken != address(0), "ACG: Invalid ERC-20 token address");
        require(
            erc20TokenFeeAddress != newToken,
            "ACG: Token address is the same."
        );
        erc20TokenFeeAddress = address(newToken);
    }

    /**
     * @dev Sets the anti bot enabled/disabled.
     * @param _option The new bot sell count.
     */
    function setAntiBotEnabled(bool _option) external onlyOwner {
        require(_option != antiBotEnabled, "Can't set the same option");
        antiBotEnabled = _option;
    }

    /**
     * @dev Sets the new bot sell count limit.
     * @param _newCount The new bot sell count.
     */
    function setMaxBotSellCount(uint256 _newCount) external onlyOwner {
        require(_newCount != _maxBotSellCount, "ACG: Same value");
        _maxBotSellCount = _newCount;
    }

    /**
     * @dev Sets the new bot sell time limit.
     * @param _newSellTimeLimitInMinutes The new bot sell block time limit in (minitues).
     */
    function setBotSellTimeLimit(
        uint256 _newSellTimeLimitInMinutes
    ) external onlyOwner {
        uint256 _newSellTimeLimitInBlocks = _newSellTimeLimitInMinutes
            .mul(60)
            .div(3); // 1 block every 3 seconds
        require(
            _newSellTimeLimitInBlocks != _botSellTimeBlockLimit,
            "ACG: Same value"
        );
        _botSellTimeBlockLimit = _newSellTimeLimitInBlocks;
    }

    /**
     * @dev Functions to set the fee wallets
     */
    function setOperationWallet(address _newWallet) external onlyOwner {
        operationWallet = _newWallet;
    }

    function setMarketingWallet(address _newWallet) external onlyOwner {
        marketingWallet = _newWallet;
    }

    function setPoolsLeaderboardWallet(address _newWallet) external onlyOwner {
        poolsLeaderboardWallet = _newWallet;
    }

    function setCommunityWallet(address _newWallet) external onlyOwner {
        communityWallet = _newWallet;
    }

    function setTreasuryOneWallet(address _newWallet) external onlyOwner {
        treasuryOneWallet = _newWallet;
    }

    function setTreasuryTwoWallet(address _newWallet) external onlyOwner {
        treasuryTwoWallet = _newWallet;
    }

    function setPenaltyWallet(address _newWallet) external onlyOwner {
        penaltyWallet = _newWallet;
    }

    /**
     * @dev Function to set the operations fee percentage
     * @param newfee The new operations fee percentage to be set
     */
    function setOperationFeePercent(
        uint256 newfee
    ) external onlyOwner feesNotBeingSet {
        // Ensure the new fee is not the same as the current fee
        require(
            newfee != _operationFee,
            "ACG: New Fee already the same as the current fee."
        );

        // Calculate the total new fees after the fee change
        uint256 totalNewFees = totalRequiredBuyFees.sub(_operationFee).add(
            newfee
        );
        // Ensure the total fees do not exceed 15%
        require(totalNewFees <= 15, "ACG: Total fees should not exceed 15%.");

        // Set the previous operations fee and update the new operations fee
        _previousOperationFee = _operationFee;
        _operationFee = newfee;

        // Update the total required buy fees to reflect the new fee configuration
        totalRequiredBuyFees = totalNewFees;
        // Update the total required fees to reflect the new fee configuration
        totalRequiredFees = totalNewFees.add(totalRequiredSellFees).add(
            _penaltyFee
        );
        // Update the total ERC20 fees to reflect the new fee configuration
        // Subtract the liquidity fee as it is handled separately
        totalERC20Fees = totalNewFees
            .add(totalRequiredSellFees)
            .add(_penaltyFee)
            .sub(_liquidityFee);
    }

    /**
     * @dev Function to set the marketing fee percentage
     * @param newfee The new marketing fee percentage to be set
     */
    function setMarketingFeePercent(
        uint256 newfee
    ) external onlyOwner feesNotBeingSet {
        // Ensure the new fee is not the same as the current fee
        require(
            newfee != _marketingFee,
            "ACG: New Fee already the same as the current fee."
        );
        // Calculate the total new fees after the fee change
        uint256 totalNewFees = totalRequiredBuyFees.sub(_marketingFee).add(
            newfee
        );
        // Ensure the total fees do not exceed 15%
        require(totalNewFees <= 15, "ACG: Total fees should not exceed 15%.");

        // Set the previous marketing fee and update the new marketing fee
        _previousMarketingFee = _marketingFee;
        _marketingFee = newfee;

        // Update the total required buy fees to reflect the new fee configuration
        totalRequiredBuyFees = totalNewFees;
        // Update the total required fees to reflect the new fee configuration
        totalRequiredFees = totalNewFees.add(totalRequiredSellFees).add(
            _penaltyFee
        );
        // Update the total ERC20 fees to reflect the new fee configuration
        // Subtract the liquidity fee as it is handled separately
        totalERC20Fees = totalNewFees
            .add(totalRequiredSellFees)
            .add(_penaltyFee)
            .sub(_liquidityFee);
    }

    /**
     * @dev Function to set the pools & leaderboard one fee percentage
     * @param newfee The new pools & leaderboard one fee percentage to be set
     */
    function setPoolsLeaderboardFeePercent(
        uint256 newfee
    ) external onlyOwner feesNotBeingSet {
        // Ensure the new fee is not the same as the current fee
        require(
            newfee != _poolsLeaderboardFee,
            "ACG: New Fee already the same as the current fee."
        );

        // Calculate the total new fees after the fee change
        uint256 totalNewFees = totalRequiredSellFees
            .sub(_poolsLeaderboardFee)
            .add(newfee);
        // Ensure the total fees do not exceed 15%
        require(totalNewFees <= 15, "ACG: Total fees should not exceed 15%.");

        // Set the previous pools & leaderboard fee and update the new pools & leaderboard fee
        _previousPoolsLeaderboardsFee = _poolsLeaderboardFee;
        _poolsLeaderboardFee = newfee;

        // Update the total required sell fees to reflect the new fee configuration
        totalRequiredSellFees = totalNewFees;
        // Update the total required fees to reflect the new fee configuration
        totalRequiredFees = totalNewFees.add(totalRequiredBuyFees).add(
            _penaltyFee
        );
        // Update the total ERC20 fees to reflect the new fee configuration
        // Subtract the liquidity fee as it is handled separately
        totalERC20Fees = totalNewFees
            .add(totalRequiredBuyFees)
            .add(_penaltyFee)
            .sub(_liquidityFee);
    }

    /**
     * @dev Function to set the community fee percentage
     * @param newfee The new community fee percentage to be set
     */
    function setCommunityFeePercent(
        uint256 newfee
    ) external onlyOwner feesNotBeingSet {
        // Ensure the new fee is not the same as the current fee
        require(
            newfee != _communityFee,
            "ACG: New Fee already the same as the current fee."
        );

        // Calculate the total new fees after the fee change
        uint256 totalNewFees = totalRequiredSellFees.sub(_communityFee).add(
            newfee
        );
        // Ensure the total fees do not exceed 15%
        require(totalNewFees <= 15, "ACG: Total fees should not exceed 15%.");

        // Set the previous community and update the new community fee
        _previousCommunityFee = _communityFee;
        _communityFee = newfee;

        // Update the total required sell fees to reflect the new fee configuration
        totalRequiredSellFees = totalNewFees;
        // Update the total required fees to reflect the new fee configuration
        totalRequiredFees = totalNewFees.add(totalRequiredBuyFees).add(
            _penaltyFee
        );
        // Update the total ERC20 fees to reflect the new fee configuration
        // Subtract the liquidity fee as it is handled separately
        totalERC20Fees = totalNewFees
            .add(totalRequiredBuyFees)
            .add(_penaltyFee)
            .sub(_liquidityFee);
    }

    /**
     * @dev Function to set the _treasuryOneFee fee percentage
     * @param newfee The new _treasuryOneFee fee percentage to be set
     */
    function setTreasuryOneFeePercent(
        uint256 newfee
    ) external onlyOwner feesNotBeingSet {
        // Ensure the new fee is not the same as the current fee
        require(
            newfee != _treasuryOneFee,
            "ACG: New Fee already the same as the current fee."
        );

        // Calculate the total new fees after the fee change
        uint256 totalNewFees = totalRequiredSellFees.sub(_treasuryOneFee).add(
            newfee
        );
        // Ensure the total fees do not exceed 15%
        require(totalNewFees <= 15, "ACG: Total fees should not exceed 15%.");

        // Set the previous treasury one fee and update the new treasury one fee
        _previousTreasuryOneFee = _treasuryOneFee;
        _treasuryOneFee = newfee;

        // Update the total required sell fees to reflect the new fee configuration
        totalRequiredSellFees = totalNewFees;
        // Update the total required fees to reflect the new fee configuration
        totalRequiredFees = totalNewFees.add(totalRequiredBuyFees).add(
            _penaltyFee
        );
        // Update the total ERC20 fees to reflect the new fee configuration
        // Subtract the liquidity fee as it is handled separately
        totalERC20Fees = totalNewFees
            .add(totalRequiredBuyFees)
            .add(_penaltyFee)
            .sub(_liquidityFee);
    }

    /**
     * @dev Function to set the _treasuryTwoFee fee percentage
     * @param newfee The new _treasuryTwoFee fee percentage to be set
     */
    function setTreasuryTwoFeePercent(
        uint256 newfee
    ) external onlyOwner feesNotBeingSet {
        // Ensure the new fee is not the same as the current fee
        require(
            newfee != _treasuryTwoFee,
            "ACG: New Fee already the same as the current fee."
        );

        // Calculate the total new fees after the fee change
        uint256 totalNewFees = totalRequiredSellFees.sub(_treasuryTwoFee).add(
            newfee
        );
        // Ensure the total fees do not exceed 15%
        require(totalNewFees <= 15, "ACG: Total fees should not exceed 15%.");

        // Set the previous treasury two fee and update the new treasury two fee
        _previousTreasuryOneFee = _treasuryTwoFee;
        _treasuryTwoFee = newfee;

        // Update the total required sell fees to reflect the new fee configuration
        totalRequiredSellFees = totalNewFees;
        // Update the total required fees to reflect the new fee configuration
        totalRequiredFees = totalNewFees.add(totalRequiredBuyFees).add(
            _penaltyFee
        );
        // Update the total ERC20 fees to reflect the new fee configuration
        // Subtract the liquidity fee as it is handled separately
        totalERC20Fees = totalNewFees
            .add(totalRequiredBuyFees)
            .add(_penaltyFee)
            .sub(_liquidityFee);
    }

    /**
     * @dev Function to set the liquidity fee percentage
     * @param newfee The new liquidity fee percentage to be set
     */
    function setLiquidityFeePercent(
        uint256 newfee
    ) external onlyOwner feesNotBeingSet {
        // Ensure the new fee is not the same as the current fee
        require(
            newfee != _liquidityFee,
            "ACG: New Fee already the same as the current fee."
        );

        // Calculate the total new fees after the fee change
        uint256 totalNewFees = totalRequiredBuyFees.sub(_liquidityFee).add(
            newfee
        );
        // Ensure the total fees do not exceed 15%
        require(totalNewFees <= 15, "ACG: Total fees should not exceed 15%.");

        // Set the previous liquidity fee and update the liquidity fee
        _previousLiquidityFee = _liquidityFee;
        _liquidityFee = newfee;

        // Update the total required buy fees to reflect the new fee configuration
        totalRequiredBuyFees = totalNewFees;
        // Update the total required fees to reflect the new fee configuration
        totalRequiredFees = totalNewFees.add(totalRequiredSellFees).add(
            _penaltyFee
        );
        // Update the total ERC20 fees to reflect the new fee configuration
        // Subtract the liquidity fee as it is handled separately
        totalERC20Fees = totalNewFees
            .add(totalRequiredSellFees)
            .add(_penaltyFee)
            .sub(_liquidityFee);
    }

    /**
     * @dev Function to set the penalty fee percentage
     * @param newfee The new penalty fee percentage to be set
     */
    function setPenaltyFeePercent(
        uint256 newfee
    ) external onlyOwner feesNotBeingSet {
        // Ensure the new fee is not the same as the current fee
        require(
            newfee != _penaltyFee,
            "ACG: New Fee already the same as the current fee."
        );

        // Ensure the total penalty fees do not exceed 20%
        require(newfee <= 20, "ACG: Total penalty fees should not exceed 20%.");

        // Set the previous penalty fee and update the penalty fee
        _previousPenaltyFee = _penaltyFee;
        _penaltyFee = newfee;

        // Update the total required fees to reflect the new fee configuration
        totalRequiredFees = newfee.add(totalRequiredBuyFees).add(
            totalRequiredSellFees
        );
        // Update the total ERC20 fees to reflect the new fee configuration
        // Subtract the liquidity fee as it is handled separately
        totalERC20Fees = newfee
            .add(totalRequiredBuyFees)
            .add(totalRequiredSellFees)
            .sub(_liquidityFee);
    }

    /**
     * @dev Function to remove all fees.
     * It checks if all the fees are already set to 0, if so, it returns without doing anything.
     * Otherwise, it stores the current fees in _previousXFee variables, where X can be Dev, Marketing, GameOne,
     * GameTwo, GameThree or Liquidity.
     * After that, it sets all the fees to 0.
     */
    function _removeAllFees() private {
        if (
            _operationFee == 0 &&
            _marketingFee == 0 &&
            _poolsLeaderboardFee == 0 &&
            _communityFee == 0 &&
            _treasuryOneFee == 0 &&
            _treasuryTwoFee == 0 &&
            _liquidityFee == 0 &&
            _penaltyFee == 0
        ) return;

        _previousOperationFee = _operationFee;
        _previousMarketingFee = _marketingFee;
        _previousPoolsLeaderboardsFee = _poolsLeaderboardFee;
        _previousCommunityFee = _communityFee;
        _previousTreasuryOneFee = _treasuryOneFee;
        _previousTreasuryTwoFee = _treasuryTwoFee;
        _previousLiquidityFee = _liquidityFee;
        _previousPenaltyFee = _penaltyFee;

        _operationFee = 0;
        _marketingFee = 0;
        _poolsLeaderboardFee = 0;
        _communityFee = 0;
        _treasuryOneFee = 0;
        _treasuryTwoFee = 0;
        _liquidityFee = 0;
        _penaltyFee = 0;
    }

    /**
     * @dev Function to restore all fees.
     * It restores all the fees to their previous values stored in `_previousXFee` variables, where X can be Dev, Marketing,
     * GameOne, GameTwo, GameThree or Liquidity.
     */
    function _restoreAllFees() private {
        _operationFee = _previousOperationFee;
        _marketingFee = _previousMarketingFee;
        _poolsLeaderboardFee = _previousPoolsLeaderboardsFee;
        _communityFee = _previousCommunityFee;
        _treasuryOneFee = _previousTreasuryOneFee;
        _treasuryTwoFee = _previousTreasuryTwoFee;
        _liquidityFee = _previousLiquidityFee;
        _penaltyFee = _previousPenaltyFee;
    }

    /**
     * @dev Function to exclude an account from paying fees.
     * @param account The address of the account to be excluded from paying fees.
     * It sets the `_isExcludedFromFee` mapping value for the given account to true,
     * effectively excluding it from paying any fees.
     */
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    /**
     * @dev Function to include an account in paying fees.
     * @param account The address of the account to be included in paying fees.
     * It sets the `_isExcludedFromFee` mapping value for the given account to false,
     *  effectively including it inpaying fees.
     */
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    /**
     * @dev Function to enable/disable swapping and liquifying tokens.
     * @param _enabled A boolean value indicating whether to enable/disable swapping and liquifying tokens.
     * It sets the `_isSwapAndGetFeesEnabled` boolean value to the given `_enabled` value
     * and emits an `SwapAndLiquifyEnabledUpdated` event.
     */
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        _isSwapAndGetFeesEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    /**
     * @dev Calculates the fees based on a given amount and fee percentage.
     * @param tAmount The amount to calculate fees for.
     * @param recipient The address to check if sell oder.
     * @return The calculated fee amount.
     */
    function _calculateFees(
        uint256 tAmount,
        address recipient
    ) private view returns (uint256) {
        uint256 _totalFees;

        if (recipient == uniswapV2Pair) {
            _totalFees = _calculateSellFee(tAmount);
        } else {
            _totalFees = _calculateBuyFee(tAmount);
        }

        return _totalFees;
    }

    // calculate buy fees
    function _calculateBuyFee(uint256 tAmount) private view returns (uint256) {
        uint256 _tOperationFee = _calculateFee(tAmount, _operationFee);
        uint256 _tMarketingFee = _calculateFee(tAmount, _marketingFee);
        uint256 _tLiquidityFee = _calculateFee(tAmount, _liquidityFee);

        uint256 _buyFees = _tOperationFee.add(_tMarketingFee).add(
            _tLiquidityFee
        );
        return _buyFees;
    }

    // calculate sell fees
    function _calculateSellFee(uint256 tAmount) private view returns (uint256) {
        uint256 _tPoolsLeaderboardFee = _calculateFee(
            tAmount,
            _poolsLeaderboardFee
        );
        uint256 _tCommunityFee = _calculateFee(tAmount, _communityFee);
        uint256 _tTreasuryOneFee = _calculateFee(tAmount, _treasuryOneFee);
        uint256 _tTreasuryTwoFee = _calculateFee(tAmount, _treasuryTwoFee);
        uint256 _tPenaltyFee = _calculateFee(tAmount, _penaltyFee);

        uint256 _sellFees = _tPoolsLeaderboardFee
            .add(_tCommunityFee)
            .add(_tTreasuryOneFee)
            .add(_tTreasuryTwoFee);

        if (tAmount >= _penaltyTxAmount) {
            _sellFees = _sellFees.add(_tPenaltyFee);
        }

        return _sellFees;
    }

    function _calculateFee(
        uint256 tAmount,
        uint256 _fee
    ) private pure returns (uint256) {
        return tAmount.mul(_fee).div(10 ** 2);
    }

    /**
     * @dev Retrieves the current supply of tokens in reflection and token form.
     * @return The current reflection supply and token supply.
     */
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _maxMintableSupply;
        uint256 tSupply = _totalSupply;
        if (rSupply < _maxMintableSupply.div(_totalSupply))
            return (_maxMintableSupply, _totalSupply);
        return (rSupply, tSupply);
    }

    /**
     * @dev Retrieves the current rate of tokens based on the current supply.
     * @return The current token rate.
     */
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    /**
     * @dev Calculates the token amount from a given reflection amount.
     * @param rAmount The reflection amount to convert to token amount.
     * @return The calculated token amount.
     */
    function tokenFromReflection(
        uint256 rAmount
    ) public view returns (uint256) {
        require(
            rAmount <= _maxMintableSupply,
            "ACG: Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    /**
     * @dev Internal function to reflect the fees to the contract
     * @param rFee The fee to be deducted from the reflection total
     * @param tFee The fee to be added to the total fees available for use
     */
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _maxMintableSupply = _maxMintableSupply.sub(rFee);
        _totalFeesCharged = _totalFeesCharged.add(tFee);
    }

    /**
     * @dev Internal function to calculate and return the reflection and token values for a given token amount
     * @param tAmount The token amount to calculate values for
     * @return rAmount The reflection amount
     * @return rTransferAmount The reflection transfer amount
     * @return rFee The reflection fee amount
     * @return tTransferAmount The token transfer amount
     * @return tFee The token fee amount
     */
    function _getValues(
        uint256 tAmount,
        address recipient
    ) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(
            tAmount,
            recipient
        );
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            _getRate()
        );
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    /**
     * @dev Internal function to calculate and return the token values for a given token amount
     * @param tAmount The token amount to calculate values for
     * @return tTransferAmount The token transfer amount
     * @return tFee The token fee amount
     */
    function _getTValues(
        uint256 tAmount,
        address recipient
    ) private view returns (uint256, uint256) {
        uint256 _totalReqFees = _calculateFees(tAmount, recipient);

        uint256 tFee = _totalReqFees;

        uint256 tTransferAmount = tAmount.sub(tFee);

        return (tTransferAmount, tFee);
    }

    /**
     * @dev Internal function to calculate and return the reflection values for a given token amount
     * @param tAmount The token amount to calculate values for
     * @param tFee The token fee amount
     * @param currentRate The current reflection rate
     * @return rAmount The reflection amount equivalent to the token amount
     *  @return rTransferAmount The reflection amount after subtracting fee and liquidity
     */
    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 currentRate
    ) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    /**
     * @dev Calculates the amount of ERC20 tokens to be deducted as fees.
     * @param _amount The amount of tokens to calculate fees for.
     * @param _fee The percentage of fees to be charged.
     * @return The amount of ERC20 tokens to be deducted as fees.
     */
    function _calculateERC20TokenFees(
        uint256 _amount,
        uint256 _fee
    ) private view returns (uint256) {
        return _amount.mul(_fee).div(totalERC20Fees);
    }

    /**
     * @dev Calculates the amount of liquidity tokens to be deducted as fees.
     * @param _amount The amount of tokens to calculate fees for.
     * @return The amount of liquidity tokens to be deducted as fees.
     */
    function _calculateLiquidityTokenFees(
        uint256 _amount
    ) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(totalRequiredFees);
    }

    /**
     * @dev Internal function to take the liquidity fee from the total transfer amount.
     * @param tLiquidity The amount of liquidity tokens to take from the transfer amount.
     */
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _balances[address(this)] = _balances[address(this)].add(rLiquidity);
    }

    /**
     * @dev Internal function to add the transaction fees to the contract's balance.
     * @param rFee The amount of reflection tokens to add to the contract's balance.
     */
    function _takeFees(uint256 rFee) private {
        _balances[address(this)] = _balances[address(this)].add(rFee);
    }

    /**
     * @dev Hook that is called before any token transfer.
     * This function checks the validity of the transaction parameters.
     * @param from The address from which the tokens are transferred.
     * @param to The address to which the tokens are transferred.
     * @param amount The amount of tokens to be transferred.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view override {
        // Ensure that neither the sender nor the recipient is the zero address.
        require(from != address(0), "ACG: transfer from the zero address");
        require(to != address(0), "ACG: transfer to the zero address");
        // Ensure that the transfer amount is greater than zero.
        require(amount > 0, "ACG: transfer amount must be greater than zero");
        // If neither the sender nor the recipient is the owner,
        // check that the transfer amount does not exceed the maximum allowed transaction amount.
        if (from != owner() && to != owner()) {
            require(
                amount <= _maxTxAmount,
                "ACG: transfer amount exceeds the maxTxAmount."
            );
        }
        // require(_balances[from] >= amount, "ACG: Not Enough Tokens.");
    }

    function _checkCanTransfer(address from) private view returns (bool) {
        uint256 _reqLimit = botLastTransferBlock[from].add(
            _botSellTimeBlockLimit
        );
        // uint256 _currentBlockNumber = block.number;

        if (
            botSellCount[from] >= _maxBotSellCount && block.number < _reqLimit
        ) {
            return false;
        }

        return true;
    }

    /**
     * @dev Transfers tokens from sender to recipient.
     *
     * Requirements:
     * - from cannot be the zero address.
     * - to cannot be the zero address.
     * - amount must be greater than zero.
     * - If from and to are not the owner, the amount must be less than or equal to _maxTxAmount.
     * - If the contract's token balance is greater than or equal to _maxTxAmount, it sets the contractTokenBalance to _maxTxAmount.
     * - If the contractTokenBalance is greater than or equal to _swapThresholdLimit and _isSwapAndGetFeesEnabled is true, it calls _swapAndGetFees() function.
     * - Sets takeFee to true initially and sets it to false only if to is not the Uniswap V2 pair or from is not the Uniswap V2 pair, indicating a stadard transfer operation respectively.
     * - If from or to belongs to _isExcludedFromFee, the takeFee value is set to false to remove the fee.
     * - Calls _tokenTransfer() function to transfer the specified amount of tokens, including the fees if takeFee is true.
     *
     * @param from Address sending the tokens.
     * @param to Address receiving the tokens.
     * @param amount Amount of tokens to transfer.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // Check transfer requirements
        _beforeTokenTransfer(from, to, amount);

        if (to == uniswapV2Pair && antiBotEnabled) {
            bool canTransfer = _checkCanTransfer(from);
            if (!canTransfer) {
                return; // Exit, Bot detected.
            }
        }

        // Get contract's token balance
        uint256 contractTokenBalance = balanceOf(address(this));

        // Set contract's token balance to maxTxAmount if it is greater than maxTxAmount
        if (contractTokenBalance >= _swapThresholdLimit) {
            contractTokenBalance = _swapThresholdLimit;
        }

        // Check if the contract's token balance is over the swap threshold limit
        bool overSwapThresholdLimit = contractTokenBalance >=
            _swapThresholdLimit;

        // If contract's token balance is greater than or equal to the swap threshold limit,
        // call _swapAndGetFees() function to swap the available fees
        if (
            overSwapThresholdLimit &&
            !_isSwappingAndGettingFees &&
            from != uniswapV2Pair &&
            _isSwapAndGetFeesEnabled
        ) {
            _swapAndGetFees(contractTokenBalance);
        }

        // Indicates if fee should be deducted from transfer
        bool takeFee = true; // Sell or Buy

        // indicating a standard transfer operation
        if (from != uniswapV2Pair && to != uniswapV2Pair) {
            takeFee = false; // standard transfer
        }

        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        // Transfer amount, including fees if takeFee is true
        _tokenTransfer(from, to, amount, takeFee);
    }

    /**
     * @dev Private helper function that transfers tokens from the sender to the recipient, while optionally taking fees and liquidity into account.
     * @param sender The address of the token sender.
     * @param recipient The address of the token recipient.
     * @param amount The amount of tokens to transfer.
     * @param takeFee A boolean value indicating whether or not fees should be taken.
     * @notice This function should only be called from within the contract as it is a private function.
     *         The function uses the `_transferStandard`, `_removeAllFees`, and `_restoreAllFees` helper functions.
     *         If `takeFee` is false, then all fees are temporarily removed before the transfer and then restored afterwards.
     */
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) _removeAllFees();

        _transferStandard(sender, recipient, amount);

        if (!takeFee) _restoreAllFees();
    }

    /**
     * @dev Private helper function that transfers tokens from the sender to the recipient, while taking fees and liquidity into account.
     * @param sender The address of the token sender.
     * @param recipient The address of the token recipient.
     * @param tAmount The amount of tokens to transfer.
     * @notice This function should only be called from within the contract as it is a private function.
     *         The function uses the `_getValues`, `_takeLiquidity`, `_takeFees`, and `_reflectFee` helper functions.
     *         The `_balances` mapping should be updated accordingly.
     *         Emits a `Transfer` event with the sender, recipient, and the amount of tokens transferred.
     */
    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getValues(tAmount, recipient);
        _balances[sender] = _balances[sender].sub(rAmount);
        _balances[recipient] = _balances[recipient].add(rTransferAmount);

        // take fees
        _takeFees(rFee);

        _reflectFee(rFee, tFee);

        if (recipient == uniswapV2Pair && antiBotEnabled) {
            _reflectBot(sender); // update the bot status
        }

        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**
     * @dev Private helper function that updates the bot sell count for a given address if necessary.
     * @param sender The address of the sender.
     * @notice This function should only be called from within the contract as it is a private function.
     *         The function checks if the current block number is greater than or equal to the required limit.
     *         If it is, the botSellCount for the sender is set to 1. If it's not, the botSellCount is incremented by 1.
     *         The botLastTransferBlock is updated with the current block number.
     */
    function _reflectBot(address sender) private {
        // Calculate the required limit based on the botLastTransferBlock and the _botSellTimeBlockLimit
        uint256 _reqLimit = botLastTransferBlock[sender].add(
            _botSellTimeBlockLimit
        );

        // Get the current block number
        uint256 _currentBlockNumber = block.number;

        // Check if the current block number is greater than or equal to the required limit
        if (_currentBlockNumber >= _reqLimit) {
            // If it is, set the botSellCount for the sender to 1
            botSellCount[sender] = 1;
        } else {
            // If it's not, increment the botSellCount for the sender by 1
            botSellCount[sender]++;
        }

        // Update the botLastTransferBlock with the current block number
        botLastTransferBlock[sender] = _currentBlockNumber;
    }

    /**
     * @dev Swaps the contract's token balance for BUSD/USDT/... and transfers the resulting fees to the respective wallets.
     * @param contractTokenBalance The amount of tokens in the contract's balance to swap and collect fees for.
     * @notice This function should only be called from within the contract as it is a private function.
     *         The `_liquidityFee` value should be greater than 0 in order for the function to swap and liquify tokens.
     *         The `erc20TokenFeeAddress` contract should be a valid ERC20 token contract address.
     *         The function uses the `_calculateLiquidityTokenFees`, `_swapAndLiquify`, `_swapTokensForTokens`, and `_calculateAvailableFeesAndTransfer` helper functions.
     *         Emits a `SwapAndGetFees` event with the amount of tokens swapped and the resulting fees transferred.
     */
    function _swapAndGetFees(uint256 contractTokenBalance) private lockTheSwap {
        uint256 availableAmount = contractTokenBalance;

        if (_liquidityFee > 0) {
            uint256 liquidityAmount = _calculateLiquidityTokenFees(
                contractTokenBalance
            );
            // for adding liquidity
            _swapAndLiquify(liquidityAmount);

            availableAmount = contractTokenBalance.sub(liquidityAmount);
        }

        // swap tokens for BUSD/USDT/...
        _swapTokensForTokens(availableAmount);

        // how much BUSD/USDT/... we just swapped
        uint256 newBalance = IERC20(erc20TokenFeeAddress).balanceOf(
            address(this)
        );

        _calculateAvailableFeesAndTransfer(newBalance);

        emit SwapAndGetFees(contractTokenBalance, newBalance, availableAmount);
    }

    /**
     * @dev Private helper function that swaps the specified amount of tokens for BNB, and adds the resulting liquidity to the liquidity pool.
     * @param liquidityAmount The amount of tokens to swap and add to the liquidity pool.
     * @notice This function should only be called from within the contract as it is a private function.
     *         The function splits the liquidity amount into two halves.
     *         The first half is swapped for BNB using the `_swapTokensForBnb` helper function.
     *         The second half is added to the liquidity pool using the `_addLiquidity` helper function.
     *         Emits a `SwapAndLiquify` event with the liquidity amount, the new BNB balance, and the amount of tokens added to the liquidity pool.
     */
    function _swapAndLiquify(uint256 liquidityAmount) private {
        // Split the liquidity amount into two halves
        uint256 half = liquidityAmount.div(2);
        uint256 otherHalf = liquidityAmount.sub(half);

        // Swap the first half of the liquidity amount for BNB
        _swapTokensForBnb(half);

        // Get the new BNB balance of the contract
        uint256 newBalance = address(this).balance;

        // Add the second half of the liquidity amount and the new BNB balance to the liquidity pool
        _addLiquidity(otherHalf, newBalance);

        // Emit a `SwapAndLiquify` event with the liquidity amount, the new BNB balance, and the amount of tokens added to the liquidity pool
        emit SwapAndLiquify(liquidityAmount, newBalance, otherHalf);
    }

    /**
     * @dev Calculates the fees to be deducted and transfers them to their respective wallets.
     * @param totalAmount The total amount of tokens to calculate fees for.
     */
    function _calculateAvailableFeesAndTransfer(uint256 totalAmount) private {
        // Calculate the amount of fees to be transferred to each wallet
        uint256 operationAmount = _calculateERC20TokenFees(
            totalAmount,
            _operationFee
        );
        uint256 marketingAmount = _calculateERC20TokenFees(
            totalAmount,
            _marketingFee
        );
        uint256 poolsLeaderboardAmount = _calculateERC20TokenFees(
            totalAmount,
            _poolsLeaderboardFee
        );
        uint256 communityAmount = _calculateERC20TokenFees(
            totalAmount,
            _communityFee
        );
        uint256 treasuryOneAmount = _calculateERC20TokenFees(
            totalAmount,
            _treasuryOneFee
        );
        uint256 treasuryTwoAmount = _calculateERC20TokenFees(
            totalAmount,
            _treasuryTwoFee
        );
        uint256 penaltyAmount = _calculateERC20TokenFees(
            totalAmount,
            _penaltyFee
        );

        // Transfer tokens to each wallet
        _transferFeesToWallet(operationWallet, operationAmount);
        _transferFeesToWallet(marketingWallet, marketingAmount);
        _transferFeesToWallet(poolsLeaderboardWallet, poolsLeaderboardAmount);
        _transferFeesToWallet(communityWallet, communityAmount);
        _transferFeesToWallet(treasuryOneWallet, treasuryOneAmount);
        _transferFeesToWallet(treasuryTwoWallet, treasuryTwoAmount);
        _transferFeesToWallet(penaltyWallet, penaltyAmount);
    }

    /**
     * @dev Transfers the given amount of tokens from the `erc20TokenFeeAddress` contract to the specified wallet address.
     * @param _wallet The address of the wallet to transfer tokens to.
     * @param _amount The amount of tokens to transfer.
     * @notice This function should only be called from within the contract as it is a private function.
     *         Also, the `erc20TokenFeeAddress` contract should be a valid ERC20 token contract address.
     *         The tokens transferred through this function are intended to be used as fees for the contract's services.
     */
    function _transferFeesToWallet(address _wallet, uint256 _amount) private {
        IERC20(erc20TokenFeeAddress).transfer(_wallet, _amount);
    }

    /**
     * @dev Function to swap ERC20 tokens for BNB using the UniswapV2Router02
     * @param tokenAmount The amount of ERC20 tokens to be swapped for BNB
     * Effects:
     * Approves the specified tokenAmount to be spent by the UniswapV2Router02 contract
     * Swaps the specified tokenAmount of ERC20 tokens for BNB
     */
    function _swapTokensForBnb(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WAVAX(); // BNB

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this), // address(uniswapV2Pair)
            block.timestamp.add(3000)
        );
    }

    /**
     * @dev Function to add liquidity to Pancake for this ERC20 token and WBNB
     * @param tokenAmount The amount of ERC20 tokens to add to the liquidity pool
     * @param ethAmount The amount of WBNB to add to the liquidity pool
     * Effects:
     * Approves the specified tokenAmount to be spent by the UniswapV2Router02 contract
     * Adds the specified tokenAmount of ERC20 tokens and ethAmount of WBNB to the Pancake liquidity pool
     * Sends the liquidity pool tokens to the contract owner
     */
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp.add(3000)
        );
    }

    /**
     * @dev Function to swap ERC20 tokens for another ERC20 token using the UniswapV2Router02
     * @param tokenAmount The amount of ERC20 tokens to be swapped for another ERC20 token
     * Effects:
     * Approves the specified tokenAmount to be spent by the UniswapV2Router02 contract
     * Swaps the specified tokenAmount of ERC20 tokens for another ERC20 token that has the erc20TokenFeeAddress
     */
    function _swapTokensForTokens(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WAVAX();
        path[2] = address(erc20TokenFeeAddress);

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp.add(3000)
        );
    }

    /* Helper functions */

    /**
     * @dev Function to manually swap BNB tokens for ETH
     * @param amount The amount of BNB tokens to be swapped for ETH
     * Requirements:
     * Only the contract owner can call this function
     * The specified amount must be greater than or equal to the swap threshold limit
     * The contract balance must be greater than or equal to the swap threshold limit
     * Effects:
     * Swaps the specified amount of BNB tokens for ETH
     */
    function manualBNBSwap(uint256 amount) external onlyOwner {
        require(
            amount >= _swapThresholdLimit,
            "ACG: Amount is less than swap threshold limit"
        );
        uint256 balance = balanceOf(address(this));
        require(
            balance >= _swapThresholdLimit,
            "ACG: Contract balance is less than swap threshold limit"
        );
        _swapTokensForBnb(amount);
    } // need a check

    /**
     * @dev Function to manually swap tokens for ERC20 and get fees
     * @param amount The amount of tokens to be swapped for ERC20 and to get fees
     * Requirements:
     * Only the contract owner can call this function
     * The specified amount must be greater than or equal to the swap threshold limit
     * The contract balance must be greater than or equal to the swap threshold limit
     * Effects:
     * Swaps the specified amount of tokens for ERC20 and gets fees
     * Deducts the specified amount from the total fees available
     */
    function manualERC20Swap(uint256 amount) external onlyOwner lockTheSwap {
        require(
            amount >= _swapThresholdLimit,
            "ACG: Amount is less than swap threshold limit"
        );
        uint256 balance = balanceOf(address(this));
        require(
            balance >= _swapThresholdLimit,
            "ACG: Contract balance is less than swap threshold limit"
        );
        _swapAndGetFees(amount);
    }

    /**
     * @dev Function to automatically swap tokens for ERC20 and get fees
     * Requirements:
     * Only the contract owner can call this function
     * The contract balance must be greater than or equal to the swap threshold limit
     * Effects:
     * Swaps the total fees available of tokens for ERC20 and gets fees
     * Deducts the previous total fees available from the new total fees available
     */
    function autoERC20Swap() external onlyOwner {
        uint256 balance = balanceOf(address(this));
        require(
            balance >= _swapThresholdLimit,
            "ACG: Contract balance is less than swap threshold limit"
        );
        _swapAndGetFees(balance);
    }

    /**
     * @dev Function to recover BNB from the contract to the owner address
     * @param _amount The amount of BNB to be recovered
     * Requirements:
     * Only the contract owner can call this function
     * The contract must have a balance equal to or greater than the amount to be recovered
     * Effects:
     * Transfers the specified amount of BNB to the owner address
     */
    function recoverBNB(uint256 _amount) external onlyOwner {
        uint256 balance = address(this).balance;
        require(
            balance >= _amount,
            "ACG: Cannot recover more than the available balance"
        );
        payable(owner()).transfer(_amount);
    }

    /**
     * @dev Function to recover BNB from the contract to a specified wallet address
     * @param _to The wallet address to which BNB will be transferred
     * @param _amount The amount of BNB to be recovered
     * Requirements:
     * Only the contract owner can call this function
     * The contract must have a balance equal to or greater than the amount to be recovered
     * Effects:
     * Transfers the specified amount of BNB to the specified wallet address
     */
    function recoverBNBToWallet(
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(_to != address(0), "ACG: transfer to the zero address");
        uint256 balance = address(this).balance;
        require(
            balance >= _amount,
            "ACG: Cannot recover more than the available balance"
        );
        payable(_to).transfer(_amount);
    }

    /**
     * @dev Function to recover ERC20 tokens from the contract to the owner address
     * @param _token The address of the ERC20 token to be recovered
     * @param _amount The amount of ERC20 tokens to be recovered
     * Requirements:
     * Only the contract owner can call this function
     * The contract must have a balance of at least _amount of the specified ERC20 token
     * Effects:
     * Transfers the specified amount of the specified ERC20 token to the owner address
     */
    function recoverERC20Tokens(
        address _token,
        uint256 _amount
    ) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(
            balance >= _amount,
            "ACG: Cannot recover more than available balance"
        );
        IERC20(_token).transfer(owner(), _amount);
    }

    /**
     * @dev Function to recover ERC20 tokens from the contract to a specified wallet address
     * @param _token The address of the ERC20 token to be recovered
     * @param _to The wallet address to which the ERC20 tokens will be transferred
     * @param _amount The amount of ERC20 tokens to be recovered
     * Requirements:
     * Only the contract owner can call this function
     * The _to address must not be the zero address
     * The contract must have a balance of at least _amount of the specified ERC20 token
     * Effects:
     * Transfers the specified amount of the specified ERC20 token to the specified wallet address
     */
    function recoverERC20TokensToWallet(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(_to != address(0), "ACG: transfer to the zero address");
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(
            balance >= _amount,
            "ACG: Cannot recover more than available balance"
        );
        IERC20(_token).transfer(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner - Disabled.
     */
    // function renounceOwnership() public virtual onlyOwner {
    //     _transferOwnership(address(0));
    // }

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     * _Available since v3.4._
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
     * _Available since v3.4._
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
     * _Available since v3.4._
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
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}