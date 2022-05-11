// SPDX-License-Identifier: MIT
/**
   SPEAR features:

   1 Quadrillion Supply (that's 1 million billions; 10T = 1% of the supply)
   5% to holders and 5% to liquidity on every transaction
   49% tokens sent to reward pool
   2% for development/marketing
   25% to contract owned locked liquidity
   24% for airdrops to whitelist, other airdrops, marketing, etc...  will end up burning the rest ... no limits on the wallet
   100% of new liquidity is owned by the contract
 */

import "../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import "./GenericDex.sol";
import "./AntiSniper.sol";
import "./ERC20Metadata.sol";
import "./SwapAndLiquify.sol";
import "./SpearERC20Permit.sol";
import "./WhitelistWallet.sol";

pragma solidity >=0.8.13;

library SpearConstants {
    uint256 constant rewardPerc           =  4900;
    uint256 constant teamUnlockedPerc     =   100;
    uint256 constant teamLockedPerc       =   100; // see teamLockedPerc_durationSec
    uint256 constant lockedPerc           =  2500;
    uint256 constant communityPerc        =  2400;
    uint256 constant totalPerc            = 10000;

    uint256 constant rCheckSum             = rewardPerc + teamUnlockedPerc + teamLockedPerc + lockedPerc + communityPerc; // Should be 100 -- checked in initialize()
    uint256 constant rCheckSumShouldBe     = totalPerc;

    //uint8 constant sniperProtectionBlocks = 8;

    uint8 constant DECIMALS = 9;
    uint256 constant teamLockedPerc_durationSec = 1 * 365 * 1 days; // 1 year lockup
    uint256 constant maxPerSwapAndLiquify = 5*10**5 * 10**12; // 5*10**5/10**DECIMALS =  1/2000 = 0.0005 = 5bps of initial supply = 
    uint256 constant minPerSwapAndLiquify = maxPerSwapAndLiquify;
    uint256 constant transactionFeeRewardPerc           =   500;
    uint256 constant transactionFeeLiquidityPerc        =   500;
    uint256 constant transactionFeeTotalPerc            =  1000;
    uint256 constant transactionFeePercBasis            = 10000;
    
    uint256 constant specialFeeForPurchasesPerc         = 58;
    uint256 constant teamPortionOfSpecialFeePerc        = 10;
    
    uint256 constant transferSizeCap                    = 10**9 * 10**DECIMALS; //1 Billion
    uint256 constant transferSizeCap_durationSec        = 20 minutes;
    
    uint256 constant tCheckSum         = transactionFeeRewardPerc + transactionFeeLiquidityPerc;
    uint256 constant tCheckSumShouldBe = transactionFeeTotalPerc;
}
 
contract SpearLiquidityDrive is Ownable {
    using Address for address;


    //FAIR LAUNCH
    uint256 public totalDonated;
    uint256 internal constant SENTINEL = type(uint256).max;
    mapping (address => uint256) private _donation;
    mapping (address => uint256) private _claimed;
    uint256 public totalClaimableTokens;
    uint256 public totalClaimedTokens;
    uint256 public endedOn;
    uint256 private estimatedPercentageOfSupply;
    uint256 public minDonation;
    bool public anyDonor;
    bool public anyClaimant;
    address public onlyClaimant;
    
    IGenericToken public quoteToken;
    IGenericToken public token; 

    uint256 public participants;
    uint256 public totalTxs;

    event LiquidityDonation(
        address from,
        address claimant,
        uint256 donation
    );

    event TokenClaim(
        address from,
        uint256 tokens
    );


    modifier notEnded {
        require(endedOn == 0, "Token already succcessfully launched");
        _;
    }

    modifier donorOnly {
        require(anyDonor || _donation[_msgSender()]>0,"You do not have permission to donate");
        _;
    }

    constructor (uint256 _estimatedPercentageOfSupply, IGenericToken quoteToken_, uint256 minDonation_, bool anyDonor_, address onlyClaimant_, bool anyClaimant_) {
        require(_estimatedPercentageOfSupply > 0 && _estimatedPercentageOfSupply <= 35, "estimate not in range");

        //REVIEW set owner and allow self-destruct on upgrade?

        //get a handle on the token
        token = IGenericToken(owner());
        quoteToken = IGenericToken(quoteToken_);
        minDonation = minDonation_;

        //claimable will use an estimate until the drive is over
        estimatedPercentageOfSupply = _estimatedPercentageOfSupply;
        anyDonor = anyDonor_;
        anyClaimant = anyClaimant_;
        onlyClaimant = onlyClaimant_;
        _donation[owner()] = SENTINEL;
    }

     /**
     * @dev Receive function to handle AVAX that was sent straight to the contract
     */
    receive() external payable {
        revert("Do not send funds directly to this contract");
    }

    function allowDonation(address a, bool t) public onlyOwner {
        if (a == address(0)) {
            require(t,"Allowing anyone to donate required parameters 0,true");
            anyDonor = true;
            return;
        } else {
            anyDonor = false;
            if (t) {
                if (_donation[a]==0)
                    _donation[a] = SENTINEL;
            } else {
                require(_donation[a] == SENTINEL, "Address has active donation");
                _donation[a] = 0;
            }
        }
    }

    function  changeClaimant(address claimant) public payable notEnded donorOnly returns (uint256) {
        address _sender = _msgSender();
        
        if (claimant == address(0))
            claimant = _sender;

        require((onlyClaimant!=address(0) && claimant == onlyClaimant) || (onlyClaimant==address(0) && claimant == _sender) || anyClaimant, "Disallowed claimant");
            
        uint256 temp = _donation[_sender];
        if (temp == SENTINEL)
            temp = 0;

        require(temp>0, "Sender has not donated");
        
        _donation[_sender] = SENTINEL;
        
        uint256 ownerDonation = _donation[owner()];
        if (ownerDonation == SENTINEL)
            ownerDonation = 0;
        
        _donation[owner()] = ownerDonation + (temp);
        
        emit LiquidityDonation(_sender, claimant, 0); //the prior LiquidityDonation(_sender,_sender) contains the value
        return temp;
    }
    
    function  donateFor(address claimant, uint256 qAmount) public notEnded donorOnly returns (uint256) {
        //AVAX
        //require(msg.value >= 0.1 ether, "Minimum donation is 0.1");
        require(qAmount >= minDonation, "Below minimum donation");
        
        address _sender = _msgSender();
        if (claimant == address(0))
            claimant = _sender;
        
        require((onlyClaimant!=address(0) && claimant == onlyClaimant) || (onlyClaimant==address(0) && claimant == _sender) || anyClaimant, "Disallowed claimant");

        //uint256 _value = msg.value;
        quoteToken.transferFrom(_sender, address(this), qAmount);

        //track participants
        uint256 temp = _donation[_sender];
        if (temp == 0 || temp == SENTINEL) {
            participants = participants + (1); //NOTE, this will be incorrect if donateFor() after changeClaimant() [could use _claimed if important to fix]
        }
        
        //add donation
        temp = _donation[claimant];
        if (temp == SENTINEL)
            temp = 0;
            
        _donation[claimant] = temp + (qAmount);
        
        totalDonated = totalDonated + (qAmount);

        emit LiquidityDonation(_sender, claimant, qAmount);

        totalTxs = totalTxs + (1);
        return 0;
    }
    
    function  claimTokens() external returns (uint256) {
        require(endedOn > 0, "Token not launched yet");
        
        address claimant = _msgSender();

        require(_claimed[claimant] == 0, "This account has already claimed tokens");
        
        //check if there are tokens to claim
        uint256 tokens = availableOf(claimant);
        require(tokens > 0, "No tokens available");

        _claimed[claimant] = tokens;
        
        //Send the tokens
        token.transfer(claimant, tokens);

        emit TokenClaim(claimant, tokens);

        totalClaimedTokens = totalClaimedTokens + (tokens);

        totalTxs = totalTxs + (1);
        return 0;
    } 

    function end() onlyOwner notEnded external {
        require(token.balanceOf(address(this)) > 0, "Tokens must be transfered to the drive before it can be ended");

        //donations will no longer be processed
        endedOn = block.timestamp;

        //Set the amount of tokens to be distributed
        totalClaimableTokens = token.balanceOf(address(this));

        //transfer avax funds to token, will be used to add liquidity
        //address payable tokenAddr = payable(address(token));
        //tokenAddr.transfer(address(this).balance);

        //transfer quoteToken funds to token, will be used to add liquidity
        quoteToken.transfer(address(token), quoteToken.balanceOf(address(this)));
    }

    function claimAVAX() onlyOwner external {
        address payable tokenAddr = payable(address(token));
        tokenAddr.transfer(address(this).balance);
    }

    function donationsOf(address from) public view returns (uint256) {
        return  _donation[from]; 
    }

    function availableOf(address from) public view returns (uint256) {
        if (totalDonated == 0)
            return 0;
        
        uint256 temp = _donation[from];
        if (temp == 0 || temp == SENTINEL)
            return 0;
        
        uint256 totalTokens = (totalClaimableTokens > 0) ? totalClaimableTokens : token.totalSupply() * (estimatedPercentageOfSupply) / (100);
        return totalTokens * (temp) / (totalDonated);
    }

    function claimedOf(address from) public view returns (uint256) {
        return _claimed[from];
    }
}

contract SpearTeamLocker  {
    IGenericToken token;
    uint256 notBefore;
    address payable releaseTo;

    constructor(address token_,address payable releaseTo_,uint256 notBefore_) {
        require(notBefore_ > block.timestamp,"notBefore must be in the future");
        require(releaseTo_ != token_,"releaseTo should not be the token");
        token = IGenericToken(token_);
        releaseTo = releaseTo_;
        notBefore = notBefore_;
    }

    function releaseTokens() public {
        require(block.timestamp > notBefore, "too soon");
        token.transfer(releaseTo,token.balanceOf(address(this)));
    }

    //in case someone does a selfdestruct send
    function releaseBalance() public {
        releaseTo.transfer(address(this).balance);
    }

    receive() external payable {revert("Do not send funds directly to this contract");}   
}

abstract contract Spear_base is  CanSwapAndLiquify, AntiSniper, Initializable, Ownable, ERC20Metadata {
    using Address for address;

    mapping (address => uint256) internal _scaledBalance;
    mapping (address => uint256) internal _unscaledBalance;
    mapping (address => mapping (address => uint256)) internal _allowances;

    mapping (address => bool) internal _isExcludedFromFee;

    mapping (address => bool) internal _isExcludedFromReward;
    address[] internal _excludedFromRewardsArray;
   
    uint8 internal constant DECIMALS = 9;
    uint256 internal constant _initialSupply = 10**12 * 10**DECIMALS; // 1T
    
    uint256 internal _remainingScaledSupply;
    uint256 internal _tFeeTotal;

    uint256 public transactionFeeRewardPerc;
    uint256 public transactionFeeLiquidityPerc;
    uint256 public transactionFeePercBasis;

    SpearLiquidityDrive public liquidityDrive;
    uint256 public campaignPeriod;

    SpearTeamLocker public teamLocker;
    address payable public teamWallet;
    address public communityWallet;
    address public rewardWallet;
    
    uint256 public startedOn;
    uint256 public launchedOn;
    uint256 public endOn;

    address[] internal _holders;
    mapping (address => uint32) internal _holdersIndexPlusOne;

    uint256 public _purchasedTotalPause;
    uint256 internal _swapMaxTBps;
    uint256 internal _sweepMaxQBps;
    uint256 internal _sweepMaxQ;
    uint256 internal _swapLowWater;

    bool public _sweepEnabled;
    
    uint256 internal _sweepMaxT;
    uint256 public _pullOnlyBalance;
 
    constructor () {
        assert(SpearConstants.rCheckSum == SpearConstants.rCheckSumShouldBe &&
               SpearConstants.tCheckSum == SpearConstants.tCheckSumShouldBe);
        _disableInitializers();
    }

    function decimals() public pure override(ERC20Metadata) returns (uint8) {
        return DECIMALS;
    }
    

    function _checkNew(address a) internal {
        uint32 i=_holdersIndexPlusOne[a];
        if (i==0 || i==type(uint32).max) {
            _holders.push(a);
            require(_holders.length < type(uint32).max, "too many holders");
            _holdersIndexPlusOne[a] = uint32(_holders.length);
        }
    }

    function _checkZero(address a) internal {
        uint32 i = _holdersIndexPlusOne[a];
        if (i > 0 && i<type(uint32).max) {
            if (balanceOf(a)>0)
                return;
            _holdersIndexPlusOne[a] = type(uint32).max; // remember ok address
            address p = _holders[_holders.length-1];
            _holders.pop();
            if(p != a){
                _holders[i-1] = p;
                _holdersIndexPlusOne[p] = i;
            }
        }
    }
    
    function sniperTransactionIsOk(address from, address to) internal override virtual returns(bool) {
        return (from == owner() ||
                to == owner() ||
                _msgSender() == owner() ||
                _msgSender() == address(this));
    }
    
    modifier sniperAdminOnly() override (AntiSniper) { require( owner() == _msgSender(),"not sniper admin"); _; }

    function _calcScalingFactor() internal view returns(uint256) {
        // reward rate is rSupply / spearSupply
        (uint256 rSupply, uint256 uSupply) = _getCurrentSupply();
        return rSupply / (uSupply);
    }

    function _getCurrentSupply() internal view returns(uint256, uint256) {
        uint256 sSupply = _remainingScaledSupply;
        uint256 uSupply = _initialSupply;
        uint256 sb;
        uint256 ub;
        address a;
        for (uint256 i = 0; i < _excludedFromRewardsArray.length; i++) {

            a  = _excludedFromRewardsArray[i];
            sb = _scaledBalance[a];
            ub = _unscaledBalance[a];

            if (sb > sSupply || ub > uSupply) return (_remainingScaledSupply, _initialSupply);
            
            sSupply = sSupply - (sb);
            uSupply = uSupply - (ub);
        }
        
        if (sSupply < _remainingScaledSupply / (_initialSupply)) return (_remainingScaledSupply, _initialSupply);

        return (sSupply, uSupply);
    }
    
    function calcUnscaledAmount(uint256 sAmount) public view returns(uint256) {
        require(sAmount <= _remainingScaledSupply, "Amount must be less than total reflections");
        uint256 scalingFactor = _calcScalingFactor();
        return sAmount / (scalingFactor);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if(_scaledBalance[account] > 0) {
            // excluded accounts report their unscaled values in balanceOf()
            // unscaled values are only updated while the account is excluded
            // therefore, we update the unscaled value here
            _unscaledBalance[account] = calcUnscaledAmount(_scaledBalance[account]);
        }
        _isExcludedFromReward[account] = true;
        _excludedFromRewardsArray.push(account);
    }

    function setFeeExcluded(address account,bool t) public onlyOwner {
        _isExcludedFromFee[account] = t;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function balanceOf(address account) public view override returns (uint256 ret) {
        if (_isExcludedFromReward[account])
            ret = _unscaledBalance[account];
        else
            ret = calcUnscaledAmount(_scaledBalance[account]);
    }
    
    function totalSupply() public pure override returns (uint256) {
        return _initialSupply;
    }

    function _calcRewardFeeAmountForTransferAmount(uint256 _amount) private view returns (uint256) { return _amount * (transactionFeeRewardPerc) / (transactionFeePercBasis); }
    function _calcLockedLiquidityFeeAmountForTransferAmount(uint256 _amount) private view returns (uint256) { return _amount * (transactionFeeLiquidityPerc) / (transactionFeePercBasis); }
    function _transferConsideringRewardsAndFees(address from, address recipient, uint256 transferAmount,bool takeFee) internal {
        uint256 scalingFactor = _calcScalingFactor();
        
        uint256 scaledTransferAmount           = transferAmount * (scalingFactor);
        uint256 scaledNetTransferAmount;
        uint256 netTransferAmount;

        if (takeFee) {

            uint256 rewardFeeAmount                = _calcRewardFeeAmountForTransferAmount(transferAmount);
            uint256 lockedLiquidityFeeAmount       = _calcLockedLiquidityFeeAmountForTransferAmount(transferAmount);
            netTransferAmount                      = transferAmount - (rewardFeeAmount) - (lockedLiquidityFeeAmount);

            // REVIEW Elephant code calculated rLiqFee inside _lockSpearAmount ... which is correct? Elephant did lockedLiquidityFeeAmount * currentRate (based on _calcScalingFactor)
            // REVIEW make sure order of operations vs Elephant contract don't matter
            uint256 scaledRewardFeeAmount          = rewardFeeAmount * (scalingFactor);
            uint256 scaledLockedLiquidityFeeAmount = lockedLiquidityFeeAmount * (scalingFactor);
            scaledNetTransferAmount                = scaledTransferAmount - (scaledRewardFeeAmount) - (scaledLockedLiquidityFeeAmount);

            // move the amount headed for LP liquidity to address(this) where it will be picked up by _swapAndLiquify()
            _scaledBalance[address(this)] = _scaledBalance[address(this)] + (scaledLockedLiquidityFeeAmount);
            if(_isExcludedFromReward[address(this)])
                _unscaledBalance[address(this)] = _unscaledBalance[address(this)] + (lockedLiquidityFeeAmount);

            //reduce _remainingScaledSupply increase _tFeeTotal
            _remainingScaledSupply = _remainingScaledSupply - (scaledRewardFeeAmount);
            _tFeeTotal             = _tFeeTotal + (rewardFeeAmount);
        } else {
            netTransferAmount       = transferAmount;
            scaledNetTransferAmount = scaledTransferAmount;
        }

        // special fee on purchases from the LP
        if (from == address(dexPair) && !isExcludedFromFee(recipient)) recordPurchase((transferAmount * (SpearConstants.specialFeeForPurchasesPerc)) / (100));

        if (_isExcludedFromReward[from])    _unscaledBalance[from]    = _unscaledBalance[from] - (transferAmount);
        if (_isExcludedFromReward[recipient]) _unscaledBalance[recipient] = _unscaledBalance[recipient] + (netTransferAmount);
        
        _scaledBalance[from]      = _scaledBalance[from] - (scaledTransferAmount);
        _scaledBalance[recipient]   = _scaledBalance[recipient] + (scaledNetTransferAmount);
        
        emit Transfer(from, recipient, netTransferAmount);
    }

    function recordPurchase(uint256 tAmount) internal {
        if (_inRemoveLiquidity)
            return;

        (uint256 resQ,uint256 resT,) = IGenericPair(dexPair).getReserves();
        if (_spearIsToken0) (resT,resQ)=(resQ,resT);
        
        uint256 qAmount = resQ * (1000) * (tAmount) / ((resT - (tAmount)) * (997));
        //uint256 qAmount2 = 1000*(resQ-(resQ*resT)/((resT+tAmount)))/997;

        if (_sweepEnabled)
            _purchasedTotal = _purchasedTotal + qAmount;
        else
            _purchasedTotalPause = _purchasedTotalPause + qAmount;
    }

}

contract Spear_launch is Spear_base {
    //----------------------------------
    function initialize(string memory name_, string memory symbol_, address dexRouter_, address quoteToken_, uint256 minDonation_, address payable teamWallet_, address payable quoteTreasuryWallet_,
                        address communityWallet_, address rewardWallet_, uint256 campaignPeriod_, uint256 livePeriod_) public initializer {
        require(address(dexRouter_) != address(0) &&
                address(quoteToken_) != address(0) &&
                address(teamWallet_) != address(0) &&
                address(quoteTreasuryWallet_) != address(0) &&
                address(communityWallet_) != address(0) &&
                address(rewardWallet_) != address(0),
                "Invalid address supplied");
        require(campaignPeriod_ >= 300, "Period must be a minimum of 300 (5 minutes)");

        super._initialize(name_,symbol_);
        
        _transferOwnership(_msgSender());
        
        //Core Setup
        dexRouter = IGenericAVAXRouter(dexRouter_);

        teamWallet = teamWallet_;
        quoteTreasuryWallet = quoteTreasuryWallet_;
        communityWallet = communityWallet_;
        rewardWallet = rewardWallet_;
        
        _remainingScaledSupply       = (type(uint256).max - (type(uint256).max % (10**DECIMALS))) - _initialSupply;
        transactionFeeRewardPerc     = SpearConstants.transactionFeeRewardPerc;
        transactionFeeLiquidityPerc  = SpearConstants.transactionFeeLiquidityPerc;
        transactionFeePercBasis      = SpearConstants.transactionFeePercBasis;
        
        //at creation the contract owns all the tokens
        _scaledBalance[address(this)] = _remainingScaledSupply;
        emit Transfer(address(0), address(this), _initialSupply);
        excludeFromReward(address(this));
        
         // Create an exchange pair for this new token
        quoteToken = IGenericToken(quoteToken_);
        dexPair = IGenericPair(IGenericFactory(dexRouter.factory()).createPair(address(this), address(quoteToken)));
        excludeFromReward(address(dexPair));
        _spearIsToken0 = (dexPair.token0() == address(this));

        _lpBuyRecipient = new SpearLPBuyRecipient(address(this));
        liquidityDrive = new SpearLiquidityDrive(SpearConstants.lockedPerc/(SpearConstants.totalPerc/100), quoteToken, minDonation_, false/*anyDonor*/, address(this)/*onlyClaimant*/, false/*anyClaimant*/);
        liquidityDrive.transferOwnership(owner());
        
        campaignPeriod = campaignPeriod_;

        maxPerSwapAndLiquify = SpearConstants.maxPerSwapAndLiquify;
        minPerSwapAndLiquify = SpearConstants.minPerSwapAndLiquify;

        //REVIEW might be able to fold special and normal fee exclusion to one bool if they are both always true or always false
        
        //exclude owner, this contract, and liquidity drive from fee
        setFeeExcluded(owner(),                   true);
        setFeeExcluded(address(this),             true);
        setFeeExcluded(address(liquidityDrive),   true);
        setFeeExcluded(rewardWallet,              true);
        setFeeExcluded(quoteTreasuryWallet,       true);
        setFeeExcluded(communityWallet,           true);
        setFeeExcluded(teamWallet,                true);
        setFeeExcluded(address(_lpBuyRecipient),  true);
        
        excludeFromReward(rewardWallet);
        excludeFromReward(communityWallet);

        startedOn = block.timestamp;
        endOn = livePeriod_;
    }

   
    function launch() public onlyOwner returns (uint256,uint256) {
        require(launchedOn == 0, "Token already succcessfully launched");

        uint256 lapsed = block.timestamp - (startedOn);

        require(lapsed > campaignPeriod, "Anyone can launch, but only after campaingPeriod, which is still in progress");

        uint256 totalTokens = balanceOf(address(this));

        //token allocation unit
        uint256 onePerc = totalTokens / (SpearConstants.totalPerc);
        
        //token allocations
        uint256 teamUnlockedAmount      = onePerc * (SpearConstants.teamUnlockedPerc); //to owner()
        uint256 teamLockedAmount        = onePerc * (SpearConstants.teamLockedPerc); //to owner()
        uint256 rewardAmount            = onePerc * (SpearConstants.rewardPerc);
        uint256 lockedAmount            = onePerc * (SpearConstants.lockedPerc); //to liquidityDrive

        uint256 communityAmount         = // arrive at communityPerc in remainder-safe way
            totalTokens
             - (teamUnlockedAmount)
             - (teamLockedAmount)
             - (rewardAmount)
             - (lockedAmount);


        uint256 _now = block.timestamp;
        launchedOn = _now;
        endOn = _now + endOn;
        teamLocker = new SpearTeamLocker(address(this), teamWallet, _now + SpearConstants.teamLockedPerc_durationSec);
        setFeeExcluded(address(teamLocker), true);

        //Transfers to wallets excluded from rewards
        _transferSimple(address(this), address(communityWallet), communityAmount);
        _transferSimple(address(this), address(rewardWallet),    rewardAmount);
        //rewardWallet.synchronize(); //REVIEW
        
        //Transfers        
        _transferSimple(address(this), address(teamLocker),      teamLockedAmount);
        _transferSimple(address(this), address(teamWallet),      teamUnlockedAmount);
        _transferSimple(address(this), address(liquidityDrive),  lockedAmount);
        
        //End the liquidity drive; this will send avax here
        //setSniperProtection(false);
        
        liquidityDrive.end();
        if (liquidityDrive.availableOf(address(this)) > 0)
            liquidityDrive.claimTokens();

        //balances    
        //uint256 avaxBalance = address(this).balance;
        uint256 quoteBalance = quoteToken.balanceOf(address(this));

        //emit log_named_uint('spear contract quoteBalance pre liquidity add:',quoteBalance);
        //emit log_named_uint('spear contract token balance pre liquidity add:',balanceOf(address(this)));
        return (lockedAmount, quoteBalance);
    }

    function _transferSimple(
        address from,
        address to,
        uint256 amount
    ) private {
        _transferConsideringRewardsAndFees(from,to,amount,false);
    }
   
    function _approve(address, address, uint256) internal pure override(CanSwapAndLiquify) { }
    function allowance(address, address) public pure override returns (uint256) { return 0;}
    function approve(address, uint256 ) public pure override returns (bool) { return false; }
    function transfer(address to, uint256 q) public override returns (bool) { _transferSimple(_msgSender(),to,q);_checkNew(to);_checkZero(_msgSender());return true; }
    function transferFrom(address, address, uint256) public pure override returns (bool) { return false; }
}

contract Spear_running is Spear_base, ERC20Permit {

    function finalizeLaunch(uint256 lockedAmount, uint quoteBalance) public reinitializer(2) returns(bool) {
        //add base liquidity
        addLiquidity(lockedAmount, quoteBalance);

        //Complete launch and enable liquify
        _swapEnabled = true;
        _sweepEnabled = true;
        _swapMaxTBps = 10;
        _sweepMaxQBps = 10;

        ERC20Permit.initialize(name());

        //_sentSniperBlockEnd(block.number+SpearConstants.sniperProtectionBlocks);
        //_setSniperProtection(true);
        return true;
    }
    
    function reinit6() public reinitializer(6) returns(bool) {
        _pullOnlyBalance = 0;
        _sweepMaxT = 0;
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool ret) {
        //require(recipient == address(_lpBuyRecipient) || recipient==address(this) || _msgSender()==address(this),"temporary situation");
        _checkNew(recipient);
        _transfer(_msgSender(), recipient, amount);
        _checkZero(_msgSender());
        return true;
    }

    function transferFrom(address owner, address recipient, uint256 amount) public override returns (bool ret) {
        //require(recipient == address(_lpBuyRecipient) || recipient==address(this) || owner==address(this),"temporary situation");
        address spender = _msgSender();
        _checkNew(recipient);
        _transfer(owner, recipient, amount);
        uint256 temp = _allowances[owner][spender];
        if (temp < amount) revert("ERC20: transfer amount exceeds allowance");
        _approve(owner, spender, temp  - (amount));
        _checkZero(owner);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + (addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 temp = _allowances[_msgSender()][spender];
        if (temp < subtractedValue) revert("ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, temp - (subtractedValue));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcludedFromReward[sender], "Only addresses participating in rewards allowed.");
        
        uint256 scaledTransferAmount = tAmount * (_calcScalingFactor());
        
        _scaledBalance[sender] = _scaledBalance[sender] - (scaledTransferAmount);
        _remainingScaledSupply = _remainingScaledSupply - (scaledTransferAmount);
        
        _tFeeTotal = _tFeeTotal + (tAmount);
    }

    function updateRouter(address dexRouter_) onlyOwner public {
        require(dexRouter_ != address(0), "Router must be set");
        dexRouter = IGenericAVAXRouter(dexRouter_);
    }
    
    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromReward[account], "Account is already included");
        for (uint256 i = 0; i < _excludedFromRewardsArray.length; i++) {
            if (_excludedFromRewardsArray[i] == account) {
                _excludedFromRewardsArray[i] = _excludedFromRewardsArray[_excludedFromRewardsArray.length - 1];
                _unscaledBalance[account] = 0; // REVIEW -- the unscaled balance is lost?
                //_scaledBalance was updated even while the account was excluded
                _isExcludedFromReward[account] = false;
                _excludedFromRewardsArray.pop();
                break;
            }
        }
    }
    
    function getScalingFactor() public view returns(uint256) {
        return _calcScalingFactor();
    }

    function _approve(address owner, address spender, uint256 amount) internal override(CanSwapAndLiquify,ERC20Permit) {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (_sweepEnabled)
            _sweepPurchases(from, to, SpearConstants.teamPortionOfSpecialFeePerc, teamWallet, quoteTreasuryWallet, _sweepMaxQ, _sweepMaxQBps, _sweepMaxT, false);
        
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is dex pair.
        if (_swapEnabled) {
            uint256 thisBalance = balanceOf(address(this));
            if (thisBalance > _swapLowWater + _pullOnlyBalance) {
                thisBalance = thisBalance - _swapLowWater - _pullOnlyBalance;
                if (thisBalance>0)
                    _swapAndLiquify(from, to, thisBalance, type(uint256).max,0, _swapMaxTBps, false);
            }
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = !(isExcludedFromFee(from) || isExcludedFromFee(to));
        _transferConsideringRewardsAndFees(from,to,amount,takeFee);
    }


    function recordedPurchases() public view onlyOwner returns(uint256,uint256) {
        return (_purchasedTotal,_purchasedTotalPause);
    }
    
    function setTotals(uint256 pt,uint256 ptp,uint256 pob) public onlyOwner {
        _purchasedTotal = pt;
        _purchasedTotalPause = ptp;
        _pullOnlyBalance = pob;
    }
    
    function setHousekeepingBps(uint256 sweepQMax_,uint256 swapTMax_) public onlyOwner {
        _swapMaxTBps = swapTMax_;
        _sweepMaxQBps = sweepQMax_;
    }

    function setMinMaxSwapAndLiquify(uint256 min,uint256 max) public onlyOwner {
        minPerSwapAndLiquify = min;
        maxPerSwapAndLiquify = max;
    }

    function setHousekeepingAmounts(uint256 swapLowWater_,uint256 sweepMaxQ_,uint256 sweepMaxT_) public onlyOwner {
        _swapLowWater = swapLowWater_;
        _sweepMaxQ = sweepMaxQ_;
        _sweepMaxT = sweepMaxT_;
    }

    function housekeeping(address from, address to, uint256 min, uint256 max, uint256 maxq, uint256 maxTBps, uint256 maxQBps, uint256 maxT, bool doSwap, bool doSweep) public onlyOwner {
        if (doSweep){
            if (maxq == 0)
                maxq = _purchasedTotal / 10;
            _sweepPurchases(from, to, SpearConstants.teamPortionOfSpecialFeePerc, teamWallet, quoteTreasuryWallet, maxq, maxQBps, maxT, true);
        }
        if (doSwap){
            uint256 thisBalance = balanceOf(address(this));
            if (thisBalance > _swapLowWater + _pullOnlyBalance) {
                thisBalance = thisBalance - _swapLowWater - _pullOnlyBalance;
                if (thisBalance>0)
                    _swapAndLiquify(from, to, thisBalance, min,max, maxTBps, true);
            }
        }
    }

    function holders(uint i) public view onlyOwner returns(address){
        return _holders[i];
    }
    
    function holdersCount() public view onlyOwner returns(uint32) {
        return uint32(_holders.length);
    }

    function setHousekeepingEnabled(bool swapEnabled_,bool sweepEnabled_) public onlyOwner {
        _swapEnabled = swapEnabled_;
        _sweepEnabled = sweepEnabled_;
    }
    
    receive() external payable {revert("Do not send funds directly to this contract");}
    
    function claimAVAX() onlyOwner external {
        payable(owner()).transfer(address(this).balance);
    }

    function restoreLiquidity(uint256 amount,bool buyFromPool,uint256 inflatePerc) public onlyOwner {
        bool swapE = _swapEnabled;
        bool sweepE = _sweepEnabled;
        setHousekeepingEnabled(false,false);
        uint256 spearAmount = balanceOf(address(this));
        uint256 tAmount;

        if (spearAmount> _swapLowWater + _pullOnlyBalance)
            spearAmount -= _swapLowWater + _pullOnlyBalance;
        else
            spearAmount = 0;
        
        if (!buyFromPool) {
            (uint256 resQ,uint256 resT,) = dexPair.getReserves();
            if (_spearIsToken0) (resT,resQ)=(resQ,resT);
            tAmount = GenericUtils.quote(amount,resQ,resT);

           if (inflatePerc>0)
                tAmount = (tAmount * inflatePerc) / 100;

            if (spearAmount<tAmount)
                amount = GenericUtils.quote(spearAmount,resT,resQ);
            else
                spearAmount = tAmount;
        }
        
        uint256 qAmount = quoteToken.balanceOf(address(this));
        WhitelistTokenWallet(address(quoteTreasuryWallet)).transferTokenTo(quoteToken,address(this),amount);
        qAmount = quoteToken.balanceOf(address(this)) - qAmount;
        require(qAmount==amount,"mismatch");

        if (buyFromPool) {
            // generate the exchange pair path of token -> wavax
            address[] memory path = new address[](2);
            path[0] = address(quoteToken);
            path[1] = address(this);

            qAmount = qAmount/2;
            quoteToken.approve(address(dexRouter), qAmount);
        
            dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                                                                            qAmount,
                                                                            0, // accept any amount of spearToken
                                                                            path,
                                                                            address(_lpBuyRecipient),
                                                                            block.timestamp+60
                                                                            );
            _lpBuyRecipient.claim(address(this)); //claim spear
            spearAmount = balanceOf(address(this)) - _swapLowWater - _pullOnlyBalance - spearAmount;
        }

        uint256 lpowned = dexPair.balanceOf(address(this));
        tAmount = balanceOf(address(this));
        addLiquidity(spearAmount,qAmount);
        tAmount = tAmount - balanceOf(address(this));
        lpowned = dexPair.balanceOf(address(this)) - lpowned;
        setHousekeepingEnabled(swapE,sweepE);
    }

    function _sweepPurchases(address from, address, uint256 teamPerc, address teamWallet, address restWallet, uint256 maxP, uint256 maxQBps, uint256 maxt, bool over) internal lockTheSwap liquidityRemover {
        if (!over &&
            (from == address(dexPair)))
            return;
        
        uint256 Q = _purchasedTotal;

        if (Q > maxP)
            Q = maxP;
                
        if (maxQBps>0) {
            (uint256 _resQ,uint256 _resT,) = IGenericPair(dexPair).getReserves();
            if (_spearIsToken0) (_resT,_resQ)=(_resQ,_resT);
            uint256 Qmax = (_resQ * maxQBps) / 10000;
            if ( Q > Qmax )
                Q = Qmax;
        }

        if (Q == 0)
            return;

        uint256 L = dexPair.totalSupply();
        {
            address feeTo = IGenericFactory(dexRouter.factory()).feeTo();
            if (feeTo != address(0)) {
                uint256 _kLast = dexPair.kLast();
                if (_kLast != 0) {
                    (uint112 _reserve0, uint112 _reserve1, ) = dexPair.getReserves();
                    uint256 rootK = Math.sqrt(uint256(_reserve0) * (_reserve1));
                    uint256 rootKLast = Math.sqrt(_kLast);
                    if (rootK > rootKLast) {
                        uint256 numerator = L * (rootK - (rootKLast));
                        uint256 denominator = rootK * (5) + (rootKLast);
                        uint256 addFeeLiquidity = numerator / denominator;
                        if (addFeeLiquidity>0) {
                            L = L + addFeeLiquidity;
                        }
                    }
                }
            }
        }

        (uint256 resQ,uint256 resT,) = IGenericPair(dexPair).getReserves();
        if (_spearIsToken0) (resT,resQ)=(resQ,resT);

        uint256 l = Q * (L) / (resQ * (2));

        if (l<1001)
            return;
        
        l = l - 1000;

        require(dexPair.approve(address(dexRouter),l), "Approval failure during housekeeping");
        uint256 qAmount = quoteToken.balanceOf(address(this));
        uint256 tAmount = balanceOf(address(this));
        
        (resQ,resT) = dexRouter.removeLiquidity(address(quoteToken),address(this),l,0,0,address(_lpBuyRecipient),block.timestamp+100);

        _lpBuyRecipient.claim(address(this)); //claim spear
        _lpBuyRecipient.claim(address(quoteToken)); //claim usdc

        qAmount = quoteToken.balanceOf(address(this)) - qAmount;
        tAmount = balanceOf(address(this)) - tAmount;

        tAmount += _pullOnlyBalance;
        if (tAmount > maxt) {
            _pullOnlyBalance = tAmount - maxt;
            tAmount = maxt;
        } else
            _pullOnlyBalance = 0;

        if (tAmount > 0)
            qAmount += swapTokensForQuoteToken(tAmount);

        if (qAmount > 0) {
            uint256 teamAmount = qAmount * (teamPerc) / (100);
            quoteToken.transfer(address(teamWallet),teamAmount);
            quoteToken.transfer(address(restWallet),qAmount - (teamAmount)); //restWallet == treasury wallet
        }
        
        _purchasedTotal = _purchasedTotal - Q;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !Address.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

library GenericUtils {
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "qutoe(): insufficient amountA");
        require(reserveA > 0 && reserveB > 0, "quote(): zero reserve");
        amountB = amountA * (reserveB) / (reserveA);
    }
}    

interface IGenericToken {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function decimals() external view returns (uint8);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address from, address spender) external returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IGenericGraveyard {
    function getGraveyard() external returns (address);
}

interface IGenericTokenWithGraveyard is IGenericGraveyard, IGenericToken {
}

interface IGenericAVAXRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);
    function quote(uint256 amountA,uint256 reserveA,uint256 reserveB) external pure;
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );
    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline) external payable returns (uint256[] memory amounts);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
                             ) external returns (uint256 amountA, uint256 amountB);
    
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
                                                                 ) external payable;
}

interface IGenericFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function feeTo() external returns(address);
}

interface IGenericPair is IGenericToken {
    function kLast() external view returns(uint256);
    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
                 ) ;
    function token0() external view returns(address);
    function token1() external view returns(address);
    function sync() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


abstract contract AntiSniper {
    mapping (address => bool) private _isSniper;
    event SniperCaught(address sniperAddress);
    
    uint256 private sniperBlockEnd = 0;
    uint256 public snipersCaught = 0;
    bool private sniperProtection = true;

    modifier noSniper(address from,address to) {
        if (sniperProtection && !sniperTransactionIsOk(from,to) && to!=address(0)) {
            require(!isSniper(from) && !isSniper(to), "Sniper rejected.");

            if (block.number < sniperBlockEnd){
                _isSniper[to] = true;
                snipersCaught ++;
                emit SniperCaught(to);
                return;
            }
        }
        
        _;
    }

    function setSniperProtection(bool t) public sniperAdminOnly {
        _setSniperProtection(t);
    }

    function _setSniperProtection(bool t) public {
        sniperProtection = t;
    }

    function setSniperBlockEnd(uint256 e) public sniperAdminOnly {
        _setSniperBlockEnd(e);
    }

    function _setSniperBlockEnd(uint256 e) internal {
        sniperBlockEnd = e;
    }

    function isSniper(address account) public view returns (bool) {
        return _isSniper[account];
    }

    function removeSniper(address account) public sniperAdminOnly {
        require(_isSniper[account], "Account is not a recorded sniper.");
        _isSniper[account] = false;
    }

    //implement func modifying visibility you want, calling _func
    modifier sniperAdminOnly() virtual;
    function sniperTransactionIsOk(address from, address to) internal virtual returns(bool);
}

// SPDX-License-Identifier: MIT
import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

pragma solidity ^0.8.13;

abstract contract ERC20Metadata is IERC20Metadata {
    string internal _name;
    string internal _symbol;

    function _initialize(string memory name_, string memory symbol_) internal virtual {
        require(bytes(name_).length > 0 && bytes(symbol_).length > 0, "Description information must be set");
        
        //Core Setup
        _name = name_;
        _symbol = symbol_;
    }


    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure virtual returns (uint8);
}

// SPDX-License-Identifier: MIT
import "./GenericDex.sol";

pragma solidity >=0.8.13;

contract SpearLPBuyRecipient {
    address payable private _claimant;
    constructor(address claimant){
        _claimant = payable(claimant);
    }
    function claimAVAX() external {
        _claimant.transfer(address(this).balance);
    }
    function claim(address something) external {
        uint256 amount = IGenericToken(something).balanceOf(address(this));
        IGenericToken(something).transfer(_claimant,amount);
    }
    receive() payable external {revert();}
}

abstract contract CanSwapAndLiquify //is DSTest
{
    bool internal inSwapAndLiquify;
    bool public _swapEnabled = false;
    uint256 public minPerSwapAndLiquify = 0;
    uint256 public maxPerSwapAndLiquify = 0;
    IGenericPair public dexPair;
    IGenericAVAXRouter public dexRouter;
    IGenericToken public quoteToken;
    uint256 public _purchasedTotal;
    bool internal _spearIsToken0;
    bool internal _inRemoveLiquidity;
    SpearLPBuyRecipient internal _lpBuyRecipient;
    address payable public quoteTreasuryWallet;
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 quoteReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap {
        if (inSwapAndLiquify)
            return;
        
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier liquidityRemover {
        _inRemoveLiquidity = true;
        _;
        _inRemoveLiquidity = false;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual;

    function _checkSwap(address from, uint256 tAmount, uint256 overrideMin, uint overrideMax) private view returns(bool) {
        if (from == address(dexPair) ||
            (maxPerSwapAndLiquify==0 && overrideMax==0) ||
            tAmount < (overrideMin < type(uint256).max ? overrideMin:minPerSwapAndLiquify))
            return false;
        else
            return true;
    }

    function _swapAndLiquify(address from, address, uint256 half /*gas. misnomer here, is contractBalance*/, uint256 overrideMin, uint256 overrideMax, uint256 maxTBps, bool over) internal lockTheSwap    {
        
        if (!over && !_checkSwap(from, half, overrideMin,overrideMax))
            return;

        {
            uint256 max = overrideMax>0 ? overrideMax:maxPerSwapAndLiquify;
            if (half > max)
                half = max;
        }

        if (maxTBps>0) {
            (uint256 _resQ,uint256 _resT,) = IGenericPair(dexPair).getReserves();
            if (_spearIsToken0) (_resT,_resQ)=(_resQ,_resT);
            uint256 Tmax = (_resT * maxTBps) / 10000;
            if ( half > Tmax )
                half = Tmax;
        }

        if (half==0)
            return;

        uint256 otherhalf = half / (2);
        half = half - (otherhalf);

        // capture the contract's current balance.
        uint256 qAmount = quoteToken.balanceOf(address(this));

        uint256 swapResult = swapTokensForQuoteToken(half);

        // how much quoteToken did we just swap into?
        qAmount = quoteToken.balanceOf(address(this)) - (qAmount);

        qAmount = qAmount - (swapResult);
        
        // add liquidity to exchange
        uint256 lpowned = dexPair.balanceOf(address(this));

        addLiquidity(otherhalf, swapResult);
        lpowned = dexPair.balanceOf(address(this)) - lpowned;
        
        if (qAmount>0)
            quoteToken.transfer(quoteTreasuryWallet,qAmount);
        
        emit SwapAndLiquify(half, qAmount, otherhalf);
    }
    
    function swapTokensForQuoteToken(uint256 tAmount) internal returns(uint256){
        // generate the exchange pair path of token -> wavax
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(quoteToken);

        _approve(address(this), address(dexRouter), tAmount);

        uint256 sold = quoteToken.balanceOf(address(_lpBuyRecipient));

        // make the swap
        dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tAmount,
            0, // accept any amount of quoteToken
            path,
            address(_lpBuyRecipient),
            block.timestamp
        );
        sold = quoteToken.balanceOf(address(_lpBuyRecipient)) - (sold);

        _lpBuyRecipient.claim(address(quoteToken));
        return sold;
    }
    
    function addLiquidity(uint256 tAmount, uint256 qAmount) internal {
        _approve(address(this), address(dexRouter), tAmount);
        require(quoteToken.approve(address(dexRouter), qAmount), "Approval failure during addLiquidity");

        // add the liquidity
        dexRouter.addLiquidity(
            address(this),
            address(quoteToken),
            tAmount,
            qAmount,
            0, // slippage is unavoidable -- amountTokenMin
            0, // slippage is unavoidable -- amountAVAXMin
            address(this), //token owns the liquidity -- LP tokens come back to us
            block.timestamp //deadline is immediate ...
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value -= 1;
    }
}

interface IERC2612Permit {

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);
}

abstract contract ERC20Permit is IERC2612Permit {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    bytes32 public DOMAIN_SEPARATOR;

    function initialize(string memory name) internal {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")), // Version
                chainID,
                address(this)
            )
        );
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual;
        
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC2612Permit: expired deadline");

        bytes32 hashStruct =
            keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, _nonces[owner].current(), deadline));

        bytes32 _hash = keccak256(abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, hashStruct));

        address signer = ecrecover(_hash, v, r, s);
        require(signer != address(0) && signer == owner, "ERC2612Permit: Invalid signature");

        _nonces[owner].increment();
        _approve(owner, spender, amount);
    }

    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./GenericDex.sol";
import "./Whitelist.sol";

contract WhitelistTokenWallet is Whitelist {
    function approveByWLSender(IGenericToken token, uint256 amount) public onlyWhitelistedOrOwner {
        token.approve(_msgSender(),amount);
    }
    function transferTokenTo(IGenericToken token, address to, uint256 amount) public onlyWhitelistedOrOwner {
        token.transfer(to,amount);
    }
    function claimToken(address token, uint amount) public onlyOwner {
        IGenericToken(token).transfer(owner(),amount);
    }
    function claim() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    /**
     * @dev Throws if called by any account that's not whitelisted.
     */
    modifier onlyWhitelistedOrOwner() {
        require(whitelist[msg.sender] || msg.sender==owner(), 'not whitelisted');
        _;
    }

    /**
     * @dev add an address to the whitelist
     * @param addr address
     * @return success true if the address was added to the whitelist, false if the address was already in the whitelist
     */
    function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    /**
     * @dev add addresses to the whitelist
     * @param addrs addresses
     * @return success true if at least one address was added to the whitelist,
     * false if all addresses were already in the whitelist
     */
    function addAddressesToWhitelist(address[] calldata  addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

    /**
     * @dev remove an address from the whitelist
     * @param addr address
     * @return success true if the address was removed from the whitelist,
     * false if the address wasn't in the whitelist in the first place
     */
    function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }

    /**
     * @dev remove addresses from the whitelist
     * @param addrs addresses
     * @return success true if at least one address was removed from the whitelist,
     * false if all addresses weren't in the whitelist in the first place
     */
    function removeAddressesFromWhitelist(address[] calldata addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }
}