//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrantGuard.sol";

/**
 *  Contract: xGRAPE Powered by XUSD
 *  Appreciating Stable Coin Inheriting The IP Of XUSD by xSurge
 *  Visit grapefinance.app and xsurge.net to learn more about appreciating stable coins
 */
contract xGRAPE is IERC20, Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    // token data
    string private constant _name = "GrapeVine";
    string private constant _symbol = "XGRAPE";
    uint8 private constant _decimals = 18;
    uint256 private constant precision = 10**18;
    
    // Underlying Asset
    IERC20 public immutable underlying;

    // supply starts at zero
    uint256 private _totalSupply;

    // balances
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    // address -> Fee Exemption
    mapping ( address => bool ) public isTransferFeeExempt;

    // Token Activation
    bool public tokenActivated;

    // Fees
    uint256 public mintFee        = 99000;            // 1.00% mint fee
    uint256 public sellFee        = 99000;            // 1.00% redeem fee 
    uint256 public transferFee    = 99000;            // 1.00% transfer fee
    uint256 private constant feeDenominator = 10**5;

    // Fee Receiver Fees
    address public feeReceiver;
    uint256 public feeReceiverPercentage; // percentage of 100,000

    // Zapper
    address public zapper;

    // initialize some stuff
    constructor(address underlying_, address feeReceiver_) {
        require(
            underlying_ != address(0),
            'Zero Address'
        );

        // initialize underlying asset
        underlying = IERC20(underlying_);

        // Fee Exempt PCS Router And Creator For Initial Distribution
        isTransferFeeExempt[msg.sender] = true;

        // initialize fee receiver
        feeReceiver = feeReceiver_;
        feeReceiverPercentage = feeDenominator / 4; // 25% of fee is taken for receivers

        // for snowtrace to show token tracker immediately
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /** Returns the total number of tokens in existence */
    function totalSupply() external view override returns (uint256) { 
        return _totalSupply; 
    }

    /** Returns the number of tokens owned by `account` */
    function balanceOf(address account) public view override returns (uint256) { 
        return _balances[account]; 
    }

    /** Returns the number of tokens `spender` can transfer from `holder` */
    function allowance(address holder, address spender) external view override returns (uint256) { 
        return _allowances[holder][spender]; 
    }
    
    /** Token Name */
    function name() public pure override returns (string memory) {
        return _name;
    }

    /** Token Ticker Symbol */
    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    /** Tokens decimals */
    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    /** Approves `spender` to transfer `amount` tokens from caller */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
  
    /** Transfer Function */
    function transfer(address recipient, uint256 amount) external override nonReentrant returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    /** Transfer Function */
    function transferFrom(address sender, address recipient, uint256 amount) external override nonReentrant returns (bool) {
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, 'Insufficient Allowance');
        return _transferFrom(sender, recipient, amount);
    }
    
    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        // make standard checks
        require(recipient != address(0) && sender != address(0), "Transfer To Zero");
        require(amount > 0, "Transfer Amt Zero");
        // track price change
        uint256 oldPrice = _calculatePrice();
        // amount to give recipient
        uint256 tAmount = (isTransferFeeExempt[sender] || isTransferFeeExempt[recipient]) ? amount : amount.mul(transferFee).div(feeDenominator);
        // tax taken from transfer
        uint256 tax = amount.sub(tAmount);

        // subtract from sender
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        // give reduced amount to receiver
        _balances[recipient] = _balances[recipient].add(tAmount);

        // burn the tax
        if (tax > 0) {
            // Take Fee
            _takeFee(tax);
            _totalSupply = _totalSupply.sub(tax);
            emit Transfer(sender, address(0), tax);
        }
        
        // require price rises
        _requirePriceRises(oldPrice);

        // Transfer Event
        emit Transfer(sender, recipient, tAmount);
        return true;
    }

    /**
        Mint XGRAPE Tokens With The Native Token ( Smart Chain BNB )
        This will purchase BUSD with BNB received
        It will then mint tokens to `recipient` based on the number of stable coins received
        `minOut` should be set to avoid the Transaction being front runned

        @param recipient Account to receive minted XGRAPE Tokens
        @param minOut minimum amount out from BNB -> BUSD - prevents front run attacks
        @return received number of XGRAPE tokens received
     */
    function mintWithNative(address recipient, uint256 minOut) external payable returns (uint256) {
        _checkGarbageCollector(address(this));
        return _mintWithNative(recipient, minOut);
    }


    /** 
        Mint XGRAPE Tokens For `recipient` By Depositing BUSD Into The Contract
            Requirements:
                Approval from the BUSD prior to purchase
        
        @param numTokens number of BUSD tokens to mint XGRAPE with
        @param recipient Account to receive minted XGRAPE tokens
        @return tokensMinted number of XGRAPE tokens minted
    */
    function mintWithBacking(uint256 numTokens, address recipient) external nonReentrant returns (uint256) {
        _checkGarbageCollector(address(this));
        return _mintWithBacking(numTokens, recipient);
    }

    /** 
        Burns Sender's XGRAPE Tokens and redeems their value in BUSD
        @param tokenAmount Number of XGRAPE Tokens To Redeem, Must be greater than 0
    */
    function sell(uint256 tokenAmount) external nonReentrant returns (uint256) {
        return _sell(msg.sender, tokenAmount, msg.sender);
    }
    
    /** 
        Burns Sender's XGRAPE Tokens and redeems their value in BUSD for `recipient`
        @param tokenAmount Number of XGRAPE Tokens To Redeem, Must be greater than 0
        @param recipient Recipient Of BUSD transfer, Must not be address(0)
    */
    function sell(uint256 tokenAmount, address recipient) external nonReentrant returns (uint256) {
        return _sell(msg.sender, tokenAmount, recipient);
    }
    
    /** 
        Allows A User To Erase Their Holdings From Supply 
        DOES NOT REDEEM UNDERLYING ASSET FOR USER
        @param amount Number of XGRAPE Tokens To Burn
    */
    function burn(uint256 amount) external nonReentrant {
        // get balance of caller
        uint256 bal = _balances[msg.sender];
        require(bal >= amount && bal > 0, 'Zero Holdings');
        // Track Change In Price
        uint256 oldPrice = _calculatePrice();
        // take fee
        _takeFee(amount);
        // burn tokens from sender + supply
        _burn(msg.sender, amount);
        // require price rises
        _requirePriceRises(oldPrice);
        // Emit Call
        emit Burn(msg.sender, amount);
    }


    ///////////////////////////////////
    //////  INTERNAL FUNCTIONS  ///////
    ///////////////////////////////////
    
    /** Purchases XGRAPE Token and Deposits Them in Recipient's Address */
    function _mintWithNative(address recipient, uint256 minOut) internal nonReentrant returns (uint256) {        
        require(msg.value > 0, 'Zero Value');
        require(recipient != address(0), 'Zero Address');
        require(
            tokenActivated || msg.sender == this.getOwner(),
            'Token Not Activated'
        );
        
        // calculate price change
        uint256 oldPrice = _calculatePrice();
        
        // amount of underlying
        uint256 amountUnderlying = underlyingBalance();
        
        // swap BNB for stable
        uint256 received = _getUnderlying(minOut);

        // mint to recipient
        return _mintTo(recipient, received, amountUnderlying, oldPrice);
    }
    
    /** Stake Tokens and Deposits XGRAPE in Sender's Address, Must Have Prior Approval For BUSD */
    function _mintWithBacking(uint256 amount, address recipient) internal returns (uint256) {
        require(
            tokenActivated || msg.sender == this.getOwner(),
            'Token Not Activated'
        );
        // users token balance
        uint256 userTokenBalance = underlying.balanceOf(msg.sender);
        // ensure user has enough to send
        require(userTokenBalance > 0 && amount <= userTokenBalance, 'Insufficient Balance');

        // calculate price change
        uint256 oldPrice = _calculatePrice();

        // amount of underlying
        uint256 amountUnderlying = underlyingBalance();

        // transfer in token
        uint256 received = _transferIn(amount);

        // Handle Minting
        return _mintTo(recipient, received, amountUnderlying, oldPrice);
    }
    
    /** Burns XGRAPE Tokens And Deposits BUSD Tokens into Recipients's Address */
    function _sell(address seller, uint256 tokenAmount, address recipient) internal returns (uint256) {
        require(tokenAmount > 0 && _balances[seller] >= tokenAmount);
        require(seller != address(0) && recipient != address(0));
        
        // calculate price change
        uint256 oldPrice = _calculatePrice();
        
        // tokens post fee to swap for underlying asset
        uint256 tokensToSwap = isTransferFeeExempt[seller] ? 
            tokenAmount.sub(100, 'Minimum Exemption') :
            tokenAmount.mul(sellFee).div(feeDenominator);

        // value of taxed tokens
        uint256 amountUnderlyingAsset = amountOut(tokensToSwap);

        // Take Fee
        if (!isTransferFeeExempt[msg.sender]) {
            uint fee = tokenAmount.sub(tokensToSwap);
            _takeFee(fee);
        }

        // burn from sender + supply 
        _burn(seller, tokenAmount);

        // send Tokens to Seller
        require(
            underlying.transfer(recipient, amountUnderlyingAsset), 
            'Underlying Transfer Failure'
        );

        // require price rises
        _requirePriceRises(oldPrice);

        // Differentiate Sell
        emit Redeemed(seller, tokenAmount, amountUnderlyingAsset);

        // return token redeemed and amount underlying
        return amountUnderlyingAsset;
    }

    /** Handles Minting Logic To Create New XGRAPE */
    function _mintTo(address recipient, uint256 received, uint256 totalBacking, uint256 oldPrice) private returns(uint256) {
        
        // find the number of tokens we should mint to keep up with the current price
        uint256 tokensToMintNoTax = _totalSupply == 0 ?
            received : 
            _totalSupply.mul(received).div(totalBacking);
        
        // apply fee to minted tokens to inflate price relative to total supply
        uint256 tokensToMint = isTransferFeeExempt[msg.sender] ? 
                tokensToMintNoTax.sub(100, 'Minimum Exemption') :
                tokensToMintNoTax.mul(mintFee).div(feeDenominator);
        require(tokensToMint > 0, 'Zero Amount');
        
        // mint to Buyer
        _mint(recipient, tokensToMint);

        // apply fee to tax taken
        if (!isTransferFeeExempt[msg.sender]) {
            uint fee = tokensToMintNoTax.sub(tokensToMint);
            _takeFee(fee);
        }

        // require price rises
        _requirePriceRises(oldPrice);

        // differentiate purchase
        emit Minted(recipient, tokensToMint);
        return tokensToMint;
    }

    /** Takes Fee */
    function _takeFee(uint mFee) internal {
        uint256 feeToTake = ( mFee * feeReceiverPercentage ) / feeDenominator;
        if (feeToTake > 0 && feeReceiver != address(0)) {
            _mint(feeReceiver, feeToTake);
        }
    }

    /** Swaps to underlying, must get minOut underlying to be successful */
    function _getUnderlying(uint256 minOut) internal returns (uint256) {

        // previous amount of Tokens before we received any
        uint256 balBefore = underlyingBalance();

        // swap BNB For stable of choice
        (bool s,) = payable(zapper).call{value: address(this).balance}("");
        require(s, 'Failure On Zapper Transfer');

        // amount after swap
        uint256 balAfter = underlyingBalance();
        require(
            balAfter > balBefore,
            'Zero Received'
        );
        require(
            balAfter >= ( balBefore + minOut ),
            'Insufficient Out'
        );
        return balAfter - balBefore;
    }

    /** Requires The Price Of XGRAPE To Rise For The Transaction To Conclude */
    function _requirePriceRises(uint256 oldPrice) internal {
        // Calculate Price After Transaction
        uint256 newPrice = _calculatePrice();
        // Require Current Price >= Last Price
        require(newPrice >= oldPrice, 'Price Cannot Fall');
        // Emit The Price Change
        emit PriceChange(oldPrice, newPrice, _totalSupply);
    }

    /** Transfers `desiredAmount` of `token` in and verifies the transaction success */
    function _transferIn(uint256 desiredAmount) internal returns (uint256) {
        uint256 balBefore = underlyingBalance();
        require(
            underlying.transferFrom(msg.sender, address(this), desiredAmount),
            'Failure Transfer From'
        );
        uint256 balAfter = underlyingBalance();
        require(
            balAfter > balBefore,
            'Zero Received'
        );
        return balAfter - balBefore;
    }
    
    /** Mints Tokens to the Receivers Address */
    function _mint(address receiver, uint amount) private {
        _balances[receiver] = _balances[receiver].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), receiver, amount);
    }
    
    /** Burns `amount` of tokens from `account` */
    function _burn(address account, uint amount) private {
        _balances[account] = _balances[account].sub(amount, 'Insufficient Balance');
        _totalSupply = _totalSupply.sub(amount, 'Negative Supply');
        emit Transfer(account, address(0), amount);
    }

    /** Make Sure there's no Native Tokens in contract */
    function _checkGarbageCollector(address burnLocation) internal {
        uint256 bal = _balances[burnLocation];
        if (bal > 10**3) {
            // Track Change In Price
            uint256 oldPrice = _calculatePrice();
            // take fee
            _takeFee(bal);
            // burn amount
            _burn(burnLocation, bal);
            // Emit Collection
            emit GarbageCollected(bal);
            // Emit Price Difference
            emit PriceChange(oldPrice, _calculatePrice(), _totalSupply);
        }
    }
    
    ///////////////////////////////////
    //////    READ FUNCTIONS    ///////
    ///////////////////////////////////
    
    function underlyingBalance() public view returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    /** Price Of XGRAPE in BUSD With 18 Points Of Precision */
    function calculatePrice() external view returns (uint256) {
        return _calculatePrice();
    }
    
    /** Returns the Current Price of 1 Token */
    function _calculatePrice() internal view returns (uint256) {
        return _totalSupply == 0 ? 10**18 : (underlyingBalance().mul(precision)).div(_totalSupply);
    }

    /**
        Amount Of Underlying To Receive For `numTokens` of XGRAPE
     */
    function amountOut(uint256 numTokens) public view returns (uint256) {
        return _calculatePrice().mul(numTokens).div(precision);
    }

    /** Returns the value of `holder`'s holdings */
    function getValueOfHoldings(address holder) public view returns(uint256) {
        return amountOut(_balances[holder]);
    }

    ///////////////////////////////////
    //////   OWNER FUNCTIONS    ///////
    ///////////////////////////////////

    /** Activates Token, Enabling Trading For All */
    function activateToken() external onlyOwner {
        require(
            !tokenActivated,
            'Token Already Activated'
        );
        tokenActivated = true;
        emit TokenActivated(block.number);
    }
    
    function setFeeReceiver(address newReceiver) external onlyOwner {
        require(newReceiver != address(0), 'Zero Address');
        feeReceiver = newReceiver;
        emit SetFeeReceiver(newReceiver);
    }

    function setFeeReceiverPercentage(uint256 newPercentage) external onlyOwner {
        require(newPercentage <= ( 9 * feeDenominator / 10), 'Invalid Percentage');
        feeReceiverPercentage = newPercentage;
        emit SetFeeReceiverPercentage(newPercentage);
    }

    function setZapper(address newZapper) external onlyOwner {
        require(newZapper != address(0), 'Zero Address');
        zapper = newZapper;
        emit SetZapper(newZapper);
    }

    /** Withdraws Tokens Incorrectly Sent To XGRAPE */
    function withdrawNonStableToken(IERC20 token) external onlyOwner {
        require(address(token) != address(underlying), 'Cannot Withdraw Underlying Asset');
        require(address(token) != address(0), 'Zero Address');
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    /** 
        Sells Tokens On Tax Free On Behalf Of Other User Tax Free
        Prevents Locked or Inaccessible funds from appreciating indefinitely
     */
    function sellDownExternalAccount(address account) external nonReentrant onlyOwner {
        require(account != address(0), 'Zero Address');
        require(_balances[account] > 0, 'Zero Amount');

        // exempt account from fees and sell them down
        isTransferFeeExempt[account] = true;
        _sell(
            account,
            _balances[account], 
            account
        );
        isTransferFeeExempt[account] = false;

        // emit sell down event
        emit SellDownAccount(account);
    }

    /** 
        Sets Mint, Transfer, Sell Fee
        Must Be Within Bounds ( Between 0% - 2% ) 
    */
    function setFees(uint256 _mintFee, uint256 _transferFee, uint256 _sellFee) external onlyOwner {
        require(_mintFee >= 90000);       // capped at 10% fee
        require(_transferFee >= 90000);   // capped at 10% fee
        require(_sellFee >= 90000);       // capped at 10% fee
        
        mintFee = _mintFee;
        transferFee = _transferFee;
        sellFee = _sellFee;
        emit SetFees(_mintFee, _transferFee, _sellFee);
    }
    
    /** Excludes Contract From Transfer Fees */
    function setTransferFeeExempt(address Contract, bool transferFeeExempt) external onlyOwner {
        require(Contract != address(0), 'Zero Address');
        isTransferFeeExempt[Contract] = transferFeeExempt;
        emit SetPermissions(Contract, transferFeeExempt);
    }
    
    /** Mint Tokens to Buyer */
    receive() external payable {
        _checkGarbageCollector(address(this));
        _mintWithNative(msg.sender, 0);
    }
    
    
    ///////////////////////////////////
    //////        EVENTS        ///////
    ///////////////////////////////////
    
    // Data Tracking
    event PriceChange(uint256 previousPrice, uint256 currentPrice, uint256 totalSupply);
    event TokenActivated(uint blockNo);

    // Balance Tracking
    event Burn(address from, uint256 amountTokensErased);
    event GarbageCollected(uint256 amountTokensErased);
    event Redeemed(address seller, uint256 amountMDB, uint256 amountBUSD);
    event Minted(address recipient, uint256 numTokens);

    // Governance Tracking
    event SetPermissions(address Contract, bool feeExempt);
    event SetFees(uint mintFee, uint transferFee, uint sellFee);
    event SetFeeReceiver(address newReceiver);
    event SetFeeReceiverPercentage(uint256 newPercentage);
    event SetZapper(address newZapper);
    event SellDownAccount(address account);
}