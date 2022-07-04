// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IOracleV2.sol";
import "../interfaces/ITreasury.sol";
import "../AuthorizableUpgradeable.sol";
import "../interfaces/IDistributable.sol";
import "./dex/interfaces/IUniswapV2Factory.sol";
import "./dex/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "./interfaces/IMasterV2.sol";
import "./dex/interfaces/IUniswapV2Farm.sol";

contract GameV2 is ERC20BurnableUpgradeable, AuthorizableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IMasterV2;

    //Permit won't fit and currently we don't need you to approve GAME for anything but selling so it's NBD.
//    bytes32 public DOMAIN_SEPARATOR;
//    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
//    mapping(address => uint) public nonces;
//    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
//        require(deadline >= block.timestamp, 'E'); //Permit: EXPIRED
//        bytes32 digest = keccak256(
//            abi.encodePacked(
//                '\x19\x01',
//                DOMAIN_SEPARATOR,
//                keccak256(abi.encode(bytes32(0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9), owner, spender, value, nonces[owner]++, deadline))
//            )
//        );
//        address recoveredAddress = ecrecover(digest, v, r, s);
//        require(recoveredAddress != address(0) && recoveredAddress == owner, 'IS'); //Permit: INVALID_SIGNATURE
//        _approve(owner, spender, value);
//    }

    //Note: "revenue" is just a term in relation to tax bracket systems. It isn't actually revenue, but amount sold - amount bought.
    uint256 public revenue;
    uint256 public revenueIncreaseTime;
    uint256 public revenueDecreaseTime;
    uint256 public revenueTime;
    //mapping(address => bool) public revenueWhitelist; //No longer needed since we don't use transferFrom.
    uint256[] public bracketPoints;
    uint256[] public bracketRates; //Len: bracketPoints-1
    IUniswapV2Factory public factory;

    uint256 addedBalance;
    uint256 lastInitiateTime;
    IERC20Upgradeable[] public lpTokens;
    IMasterV2 public master;
    IUniswapV2Farm[] public farms; //Single stake GAME not allowed.

    address public treasury;
    address devFund;
    bool useLiquidityFormula;
    bool useLiquidityBrackets;

    struct Snapshot {
        uint256 time;
        uint256 rewardReceived;
        uint256 rewardPerShare;
    }
    Snapshot[] public holderHistory;
    mapping(address => uint256) public lastHolderSnapshotIndex;
    mapping(address => uint256) public holderRewardEarned;
    Snapshot[][] public lpHistory;
    mapping(address => uint256)[] public lastLpSnapshotIndex;
    mapping(address => uint256)[] public lpRewardEarned;
    Snapshot[] public masterHistory;
    mapping(address => uint256) public lastMasterSnapshotIndex;
    mapping(address => uint256) public masterRewardEarned;
    mapping(address => uint256) public credits;
    uint256 public totalCredits;
    struct ClaimableToken {
        address addr;
        uint256 decimals;
    }
    ClaimableToken[] public claimableTokens;
    mapping(address => uint256) public claimableTokenIndex;
    IOracleV2 public oracle;
    uint256 taxOutPrice;
    uint256 taxOutRate;
    mapping(address => uint256) gameLinkedToCredits;
    mapping(address => uint256) pendingMintRefund;
    mapping(address => uint256) pendingMintLink;
    mapping(address => bool) creditWhitelist;
    mapping(address => mapping(address => uint256)) lastPairBalance;

    //Only the operator can mint more tokens. The operator should be the MasterChef, and it should be under a 48-hour or more timelock controlled by a multisig.

    //Tax bracket multiplier must be universal, else people will be able to exploit.
    //This means that the less healthy the most recent sells, the more everyone will have to pay in taxes.
    //If 10% of liquidity was recently sold, the protocol is considered unhealthy and the sales tax is high.
    //This is updated BEFORE each sell, which means it affects the seller, too.
    //Because it is a bracket system, each slice is counted individually
    //(as in if there is $100 until the 2x point, and $200 until the 3x point, your first $100 will be taxed 1x, and the next $200 will be taxed 2x),
    //which means it doesn't matter if you do it via multiple wallets/sells or one wallet/sell.
    //Each buy (or time, fully reduced after 1 month) REDUCES this amount in the same manner, which means that the protocol can become healthy again with a balancing act.
    //At least, multiplier is 1x.
    //At max, multiplier is 10x.
    //There are 10 tax brackets, one at each percent.
    //Formula is: percentageOfGameTokensInLP*taxBracketMultiplier

    // Events.
    event IncreaseRevenue(uint256 value);
    event DecreaseRevenue(uint256 value);
    event RewardPaid(address indexed user, uint256 reward);
    event CreditsTaken(address indexed user,uint256 value);
    event CreditsGiven(address indexed user, uint256 value);

    //TODO: Hooks system. Before and after. Returns bool, false = early out. Single hook contract with function runHook(bytes32). Changeable by owner only.

    /**
     * @notice Constructs the GAME ERC-20 contract.
     */
    function initialize(address _treasury, address _devFund) public initializer {
        __Context_init_unchained();
        __ERC20_init_unchained("GAME Token", "GAME");
        __ERC20Burnable_init_unchained();
        __Ownable_init_unchained();
        __Operator_init_unchained();
        __Authorizable_init_unchained();
        __ReentrancyGuard_init_unchained();
//        uint chainId;
//        assembly {
//            chainId := chainid()
//        }
//        DOMAIN_SEPARATOR = keccak256(
//            abi.encode(
//                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
//                keccak256(bytes("GAME Token")),
//                keccak256(bytes('1')),
//                chainId,
//                address(this)
//            )
//        );
        revenueTime = 30 days;
        treasury = _treasury;
        devFund = _devFund;
        Snapshot memory genesisSnapshot = Snapshot({time : block.number, rewardReceived : 0, rewardPerShare : 0});
        holderHistory.push(genesisSnapshot);
        masterHistory.push(genesisSnapshot);
        useLiquidityFormula = false; //Can be reduced with multiple transactions, so it is false until we find a solution that won't harm little critters.
        useLiquidityBrackets = true;
        bracketPoints = [0, 100, 200, 300, 400, 500, 600, 700, 800, 900, type(uint256).max]; //Must start with 0 and end with max. Adjust these as necessary.
        bracketRates = [1000, 1300, 1600, 1900, 2200, 2500, 2800, 3100, 3400, 3700]; //If useLiquidityFormula is false.
        //bracketRates = [10000, 20000, 30000, 40000, 50000, 60000, 70000, 80000, 90000, 100000]; //If useLiquidityFormula is true.
        taxOutRate = 1000;
        taxOutPrice = 1 ether;
        //Don't forget to call setFarms and setOperator to the farm contract.
        //Don't forget to call setFactory.
        //Don't forget to call setOracle.
        //Don't forget to call setClaimableTokens.
        //Don't forget to call addLp.
    }

    //UPGRADE 3: Gas savings
    function resetLpTokenCredits() external
    {
        credits[address(lpTokens[0])] = 0;
        gameLinkedToCredits[address(lpTokens[0])] = 0;
    }

    //UPGRADE 2: These are already set. Let's save some space and remove these functions.
//    function setFactory(
//        IUniswapV2Factory _factory
//    ) external onlyOwner {
//        factory = _factory;
//    }
//
//    function setOracle(
//        IOracleV2 _oracle
//    ) external onlyOwner {
//        oracle = _oracle;
//    }
//
//    function setFunds(
//        address _treasury, address _devFund
//    ) external onlyOwner {
//        treasury = _treasury;
//        devFund = _devFund;
//    }
//
//    function setMaster(
//        IMasterV2 _master
//    ) external onlyOwner {
//        master = _master;
//    }

    //Refund for those affected by losing credits after adding liquidity after buying before the new system was in place.
//    function setCredits(
//        address[] memory addresses, uint256[] memory credit
//    ) external onlyOwner {
//        uint256 len = addresses.length;
//        require(len == credit.length, "L"); //Length does not match.
//        for(uint256 i; i < len; i += 1)
//        {
//            credits[addresses[i]] = credit[i];
//            gameLinkedToCredits[addresses[i]] = balanceOf(addresses[i]);
//        }
//    }

    function setCreditWhitelist(
        address whitelisted, bool value
    ) external onlyOwner {
        creditWhitelist[whitelisted] = value;
    }

//    function setRevenueTime(uint256 _revenueTime) external onlyAuthorized {
//        require(_revenueTime > 0 && _revenueTime <= 365 days, "Invalid revenue time.");
//        revenueTime = _revenueTime;
//    }

    //Be careful adding LP: You can't take it back. UPGRADE 2: Temporarily removed for space for setCredits.
//    function addLp(IERC20Upgradeable lpToken) public onlyAuthorized {
//        Snapshot memory genesisSnapshot = Snapshot({time : block.number, rewardReceived : 0, rewardPerShare : 0});
//        lpTokens.push(lpToken);
//        lpHistory.push();
//        lpHistory[lpHistory.length-1].push(genesisSnapshot);
//        lastLpSnapshotIndex.push();
//        lpRewardEarned.push();
//    }

//    function setClaimableTokens(
//        ClaimableToken[] memory _claimableTokens
//    ) external onlyOwner {
//        uint256 len = claimableTokens.length;
//        uint256 i;
//        for(i = 0; i < len; i += 1)
//        {
//            //Remove existing tokens
//            claimableTokenIndex[claimableTokens[i].addr] = 0;
//        }
//        delete claimableTokens;
//        len = _claimableTokens.length;
//        for(i = 0; i < len; i += 1)
//        {
//            //Add new tokens
//            require(_claimableTokens[i].decimals < 78, "Invalid decimals."); //Making sure we don't overflow. A value of 78+ overflows.
//            claimableTokens.push(_claimableTokens[i]);
//            claimableTokenIndex[_claimableTokens[i].addr] = i.add(1);
//        }
//    }

    //    function changeRevenueWhitelist(address account, bool whitelist) external onlyAuthorized {
//        revenueWhitelist[account] = whitelist;
//    }

    /**
     * @notice Operator mints GAME to a recipient
     * @param recipient_ The address of recipient
     * @param amount_ The amount of GAME to mint to
     * @return whether the process has been done
     */
    function mint(address recipient_, uint256 amount_) public onlyOperator returns (bool) {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);

        return balanceAfter > balanceBefore;
    }

//    function burn(uint256 amount) public override {
//        super.burn(amount);
//    }

    function burnFrom(address account, uint256 amount) public override onlyOperator {
        super.burnFrom(account, amount);
    }

    function getToken(address pair, bool token1) public view returns (address) {
        (bool success, bytes memory data) = pair.staticcall(abi.encodeWithSelector(bytes4(token1 ? 0xd21220a7 : 0x0dfe1681)));
        if(success && data.length == 32)
        {
            return abi.decode(data, (address));
        }
        return address(0);
    }

    function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal override {
        //Checks
        //Effects
        if(recipient == address(this))
        {
            addedBalance = addedBalance.add(amount);
        }
        _updateReward(sender); //Has safe "interactions": Only external calls are view functions.
        _updateReward(recipient); //Has safe "interactions": Only external calls are view functions.
        //Prevent credit hoarding.
        uint256 gameLinkedToCreditsOfSender = gameLinkedToCredits[sender];
        //UPGRADE 2. Fix in the case of minting. Has safe "interactions": Only external calls are view functions.
        bool senderIsGamePair;
        {
            address token0Sender = getToken(sender, false);
            if(token0Sender != address(0) && token0Sender != address(this))
            {
                address pair0Sender = factory.getPair(address(this), token0Sender);
                if(pair0Sender != address(0))
                {
                    senderIsGamePair = sender == pair0Sender;
                }
            }
            if(!senderIsGamePair)
            {
                address token1Sender = getToken(sender, true);
                if(token1Sender != address(0) && token1Sender != address(this))
                {
                    address pair1Sender = factory.getPair(address(this), token1Sender);
                    if(pair1Sender != address(0))
                    {
                        senderIsGamePair = sender == pair1Sender;
                    }
                }
            }
        }
        //////////////////
        if(senderIsGamePair)
        {
            pendingMintRefund[sender] = 0; //If we transfer for any reason, that means we're not minting and therefore the refund can disappear.
            pendingMintLink[sender] = 0;
        }
        if(gameLinkedToCreditsOfSender > 0 && !senderIsGamePair && !creditWhitelist[sender] && !creditWhitelist[recipient])
        {
            //Has safe "interactions": Only external calls are view functions.
            bool recipientIsGamePair;
            {
                address token0Recipient = getToken(recipient, false);
                if(token0Recipient != address(0) && token0Recipient != address(this))
                {
                    address pair0Recipient = factory.getPair(address(this), token0Recipient);
                    if(pair0Recipient != address(0))
                    {
                        recipientIsGamePair = recipient == pair0Recipient;
                    }
                }
                if(!recipientIsGamePair)
                {
                    address token1Recipient = getToken(recipient, true);
                    if(token1Recipient != address(0) && token1Recipient != address(this))
                    {
                        address pair1Recipient = factory.getPair(address(this), token1Recipient);
                        if(pair1Recipient != address(0))
                        {
                            recipientIsGamePair = recipient == pair1Recipient;
                        }
                    }
                }
            }
            //////////////
            uint256 creditsOfSender = credits[sender];
            uint256 creditsPercentageToTransfer = amount >= gameLinkedToCreditsOfSender ? 1e18 : amount.mul(1e18).div(gameLinkedToCreditsOfSender);
            uint256 creditsToTransfer = creditsOfSender.mul(creditsPercentageToTransfer).div(1e18);
            uint256 linkedAmount = amount >= gameLinkedToCreditsOfSender ? gameLinkedToCreditsOfSender : amount;

            if(!senderIsGamePair)
            {
                credits[sender] = creditsOfSender.sub(creditsToTransfer);
                gameLinkedToCredits[sender] = gameLinkedToCredits[sender].sub(linkedAmount);
                emit CreditsTaken(sender, creditsToTransfer);
            }

            if(recipientIsGamePair)
            {
                //Don't add credits or gameLinkedToCredits. Instead, keep track of the amount for this pair and give a refund when minting and remove it when doing anything involving a transfer.
                pendingMintRefund[recipient] = pendingMintRefund[recipient].add(creditsToTransfer);
                pendingMintLink[recipient] = pendingMintLink[recipient].add(linkedAmount);
            }
            else if(!senderIsGamePair)
            {
                credits[recipient] = credits[recipient].add(creditsToTransfer);
                gameLinkedToCredits[recipient] = gameLinkedToCredits[recipient].add(linkedAmount);
                emit CreditsGiven(recipient, creditsToTransfer);
            }
        }
        super._beforeTokenTransfer(sender, recipient, amount);
        //Interactions
    }

//    function governanceRecoverUnsupported(
//        IERC20Upgradeable _token,
//        uint256 _amount,
//        address _to
//    ) external onlyAuthorized {
//        require(address(_token) != address(this) && claimableTokenIndex[address(_token)] == 0, "Can't remove reflections.");
//        _token.transfer(_to, _amount);
//    }

//    function setFarms(
//        IUniswapV2Farm[] memory _farms
//    ) external onlyAuthorized {
//        farms = _farms;
//    }

//    function revenueIncreaseTimeUpdate(uint256 change) public onlyAuthorized {
//        revenueIncreaseTime = change;
//    }
//
//    function revenueDecreaseTimeUpdate(uint256 change) public onlyAuthorized {
//        revenueDecreaseTime = change;
//    }

    function canDecreaseAmount() public view returns (uint256) {
        if (block.timestamp <= revenueIncreaseTime) {
            return 0;
        } else if (block.timestamp >= revenueIncreaseTime.add(revenueTime)) {
            return revenue;
        } else {
            uint256 releaseTime = block.timestamp.sub(revenueDecreaseTime);
            uint256 numberRevenueTime = revenueIncreaseTime.add(revenueTime).sub(revenueDecreaseTime);
            return revenue.mul(releaseTime).div(numberRevenueTime);
        }
    }

//    function increaseRevenue(uint256 _amount) external onlyAuthorized {
//        _increaseRevenue(_amount);
//    }

    function _increaseRevenue(uint256 amount) internal {
        __decreaseRevenue(canDecreaseAmount());
        if(amount == 0) return;

        revenueIncreaseTime = block.timestamp;
        if (revenueDecreaseTime < revenueIncreaseTime) {
            revenueDecreaseTime = revenueIncreaseTime;
        }

        revenue = revenue.add(amount);
        emit IncreaseRevenue(amount);
    }

    //This is used for buys and updating revenue.
//    function decreaseRevenue(uint256 amount) external onlyAuthorized {
//        _decreaseRevenue(amount);
//    }

    function _decreaseRevenue(uint256 amount) internal {
        __decreaseRevenue(amount.add(canDecreaseAmount()));
    }

    function __decreaseRevenue(uint256 amount) internal {
        if(revenue == 0 || amount == 0) return;
        if (amount > revenue) {
            amount = revenue;
        }

        revenueDecreaseTime = block.timestamp;
        revenue = revenue.sub(amount);

        emit DecreaseRevenue(amount);
    }

    //Convenience
    //Start > end
    function taxAmountIn(uint256 start, uint256 end, uint256 liquidity) public view returns (uint256)
    {
        require(start < end, "Start must be < end");
        uint256 i;
        uint256 len = bracketRates.length;
        uint256 taxToBePaid = 0;
        uint256 amount = end.sub(start);
        uint256 newLiquidity = liquidity.add(amount); //So that it isn't in your best interest to split your trades unless you are willing to wait.
        for(i = 0; i < len; i += 1)
        {
            //TODO?: Option for brackets based on supply?
            uint256 upper = bracketPoints[i+1] == type(uint256).max ? type(uint256).max : (useLiquidityBrackets ? newLiquidity.mul(bracketPoints[i+1].sub(1)).div(10000) : bracketPoints[i+1].sub(1));

            if(start > upper) continue; //Only calculate if start <= upper tax
            //For example, if tax bracket is at 1000-1999, and our start is 2000, we should skip that bracket.
            //But if it is 1500, we should take 499 of that bracket as tax.
            uint256 lower = useLiquidityBrackets ? newLiquidity.mul(bracketPoints[i]).div(10000) : bracketPoints[i];
            if(end <= lower) break; //If end <= lower, then we've reached the end bracket.
            uint256 lowerOrStart = MathUpgradeable.max(lower, start); //The 499 explained above.
            uint256 taxableAtThisRate = upper == type(uint256).max ? end.sub(lowerOrStart) : MathUpgradeable.min(upper.sub(lowerOrStart), end.sub(lowerOrStart));
            uint256 percentageOfGameTokensInLP = amount.mul(10000).div(newLiquidity);
            uint256 taxThisBand = useLiquidityFormula ? taxableAtThisRate.mul(percentageOfGameTokensInLP).div(10000).mul(bracketRates[i]).div(10000) : taxableAtThisRate.mul(bracketRates[i]).div(10000);
            taxToBePaid = taxToBePaid.add(taxThisBand);
        }
        //With multipliers, we can go over 100%.
        if(taxToBePaid > amount) taxToBePaid = amount;
        return taxToBePaid;
    }

    function canTaxOut(address tokenOut) view public returns (bool)
    {
        //WARNING: Keep this array small for gas reasons!
//        uint256 len = claimableTokens.length;
//        for (uint256 i; i < len; i += 1) {
//            if (claimableTokens[i].addr == tokenOut) { //Can only tax if token is claimable. Generally, all tokens with farmable LPs should be included, and that list should be kept small.
//                return oracle.getPrice(address(this)) < taxOutPrice; //Price of GAME is TWAP.
//            }
//        }
        //We use a mapping that we loop through at the beginning (to remove existing entries) and end (to add new entries) in an admin function since the array will be static after being set.
        //Saves us some gas here.
        if(address(oracle) == address(0)) return false;
        return claimableTokenIndex[tokenOut] > 0 && oracle.getPrice(address(this)) < taxOutPrice;
    }

    function taxAmountOut(address tokenOut, uint256 amountOut) view public returns (uint256)
    {
        //Only tax when TWAP < $1.
        if(canTaxOut(tokenOut))
        {
            return amountOut.mul(taxOutRate).div(10000);
        }
        return 0;
    }

    function taxRate(uint256 start, uint256 end, uint256 liquidity, address tokenOut, uint256 amountOut) public view returns (uint256)
    {
        uint256 amount = end.sub(start);
        if(amount == 0) return 0;
        uint256 amountOutInGame = amount.sub(taxAmountIn(start, end, liquidity));
        //amountOut = UniswapV2Library.getAmountOut(amountOutInGame, reserveInput, reserveOutput, IUniswapV2Factory(factory).useFee());
        //Get percentage of amountOut we get.
        uint256 amountOutTaxPercentage = taxAmountOut(tokenOut, amountOut).mul(10000).div(amountOut);
        //How much we have in GAME from the second tax.
        uint256 amountOutTaxInGame = amountOutInGame.sub(amountOutInGame.mul(amountOutTaxPercentage).div(10000));
        return amount.sub(amountOutTaxInGame)
        .mul(10000)
        .div(amount);
    }

    //Hooks for DEX.
    //Liquidity is liquidity before the buy.
    function onBuy(uint256 liquidity, uint256 amount, address to, address soldToken, uint256 soldLiquidity, uint256 soldAmount) external nonReentrant returns (uint256[] memory taxOut, uint256[] memory taxIn, address[] memory taxTo)
    {
        require(msg.sender == factory.getPair(address(this), soldToken), "Mismatching pair.");
        //Decrease revenue.
        _decreaseRevenue(amount);
        taxOut = new uint256[](0);
        taxIn = new uint256[](0);
        taxTo = new address[](0);
        if(address(oracle) != address(0))
        {
            try oracle.updateIfPossible() {} catch {}
            if(canTaxOut(soldToken))
            {
                uint256 decimals = claimableTokens[claimableTokenIndex[soldToken].sub(1)].decimals;
                uint256 creditsEarned = oracle.getPrice(soldToken).mul(soldAmount).div((10)**(decimals));
                credits[to] = credits[to].add(creditsEarned);
                totalCredits = totalCredits.add(creditsEarned);
                gameLinkedToCredits[to] = gameLinkedToCredits[to].add(amount);
                emit CreditsGiven(to, creditsEarned);
            }
        }
        //TODO: Hooks before + after
    }

    function afterBuyTax(uint256 liquidity, uint256 amount, address to, address soldToken, uint256 soldLiquidity, uint256 soldAmount) external
    {
        //Do nothing.
    }

    function creditPercentageOfTotal(address user) public view returns (uint256)
    {
        if(totalCredits == 0) return 0;
        return credits[user].mul(1 ether).div(totalCredits);
    }

    function redeemTaxOutAmounts(address user) public view returns (uint256[] memory)
    {
        uint256 percentageOfTotal = creditPercentageOfTotal(user);
        uint256 len = claimableTokens.length;
        uint256[] memory amounts = new uint256[](len);
        for(uint256 i; i < len; i += 1)
        {
            IERC20Upgradeable token = IERC20Upgradeable(claimableTokens[i].addr);
            amounts[i] = (token.balanceOf(address(this)).mul(percentageOfTotal).div(1 ether));
        }
        return amounts;
    }

    function totalRedeemTaxOutAmounts() external view returns (uint256[] memory)
    {
        uint256 len = claimableTokens.length;
        uint256[] memory amounts = new uint256[](len);
        for(uint256 i; i < len; i += 1)
        {
            IERC20Upgradeable token = IERC20Upgradeable(claimableTokens[i].addr);
            amounts[i] = token.balanceOf(address(this));
        }
        return amounts;
    }

    function redeemTaxOut() nonReentrant external
    {
        require(address(oracle) != address(0), "No oracle, no tax out.");
        require(oracle.getPrice(address(this)) >= taxOutPrice, "Cannot redeem under redeem price.");
        require(credits[msg.sender] > 0, "Not enough credits to redeem.");
        uint256 len = lpTokens.length;
        for(uint256 index; index < len; index += 1)
        {
            uint256 pairBalance = lpTokens[index].balanceOf(msg.sender);
            uint256 len2 = farms.length;
            for(uint256 i; i < len2; i += 1)
            {
                IUniswapV2Farm farm = farms[i];
                pairBalance = pairBalance.add(farm.depositBalanceOf(address(lpTokens[index]), msg.sender));
            }
            require(pairBalance >= lastPairBalance[address(lpTokens[index])][msg.sender], "Need >= pair tokens from last mint.");
        }

        len = claimableTokens.length;
        bool sentToken = false;
        uint256 percentageOfTotal = creditPercentageOfTotal(msg.sender);
        totalCredits = totalCredits.sub(credits[msg.sender]);
        credits[msg.sender] = 0;
        gameLinkedToCredits[msg.sender] = 0;
        for(uint256 i; i < len; i += 1) //Careful of gas.
        {
            IERC20Upgradeable token = IERC20Upgradeable(claimableTokens[i].addr);
            if(token.balanceOf(address(this)) > 0)
            {
                token.safeTransfer(msg.sender, token.balanceOf(address(this)).mul(percentageOfTotal).div(1 ether));
                sentToken = true;
            }
        }
        require(sentToken, "Nothing to redeem.");
    }

    function _initiate() internal
    {
        if(block.timestamp <= lastInitiateTime) return;
        uint256 amountForHolders = addedBalance.mul(1).div(7); //TODO: Customization
        uint256 amountForLp = addedBalance.mul(2).div(7); //TODO: Customization
        {
            //For holders.
            uint256 amount = amountForHolders;

            //totalGameUnclaimed = totalGameUnclaimed.add(amount);

            //Calculate amount to earn
            // Create & add new snapshot
            uint256 prevRPS = getLatestHolderSnapshot().rewardPerShare;
            uint256 supply = totalSupply().sub(balanceOf(address(this)));
            uint256 len = farms.length;
            for(uint256 i; i < len; i += 1)
            {
                //Do not count rewards (or GAME stuck in that contract for some reason).
                supply = supply.sub(balanceOf(address(farms[i]))); //Single stake GAME not allowed.
            }
            len = lpTokens.length;
            for(uint256 i; i < len; i += 1)
            {
                //Do not count LP.
                supply = supply.sub(balanceOf(address(lpTokens[i])));
            }
            //Nobody earns any GAME if everyone withdraws. If that's the case, all GAME goes to the treasury's daoFund.
            uint256 nextRPS = supply == 0 ? prevRPS : prevRPS.add(amount.mul(1e18).div(supply)); //Otherwise, GAME is distributed amongst those who have not yet burned their MASTER.

            if(supply == 0 && amount > 0)
            {
                _transfer(address(this), treasury, amount);
            }

            Snapshot memory newSnapshot = Snapshot({
            time: block.number,
            rewardReceived: amount,
            rewardPerShare: nextRPS
            });
            holderHistory.push(newSnapshot);
        }
        uint256 len = lpTokens.length;
        if(len > 0)
        {
            uint256 amountEach = amountForLp.div(len);
            amountForLp = amountEach.mul(len); //Reset for rounding errors.
            for(uint256 i; i < len; i += 1)
            {
                //For LP.
                uint256 amount = amountEach;

                //totalGameUnclaimed = totalGameUnclaimed.add(amount);

                //Calculate amount to earn
                // Create & add new snapshot
                uint256 prevRPS = getLatestLpSnapshot(i).rewardPerShare;
                uint256 supply = lpTokens[i].totalSupply();
                //Nobody earns any GAME if everyone withdraws. If that's the case, all GAME goes to the treasury's daoFund.
                uint256 nextRPS = supply == 0 ? prevRPS : prevRPS.add(amount.mul(1e18).div(supply)); //Otherwise, GAME is distributed amongst those who have not yet burned their MASTER.

                if(supply == 0 && amount > 0)
                {
                    _transfer(address(this), treasury, amount);
                }

                Snapshot memory newSnapshot = Snapshot({
                time: block.number,
                rewardReceived: amount,
                rewardPerShare: nextRPS
                });
                lpHistory[i].push(newSnapshot);
            }
        }
        {
            uint256 amountForMaster = addedBalance.sub(amountForLp).sub(amountForHolders);
            //For master.
            uint256 amount = amountForMaster;
            //totalGameUnclaimed = totalGameUnclaimed.add(amount);

            //Calculate amount to earn
            // Create & add new snapshot
            uint256 prevRPS = getLatestMasterSnapshot().rewardPerShare;
            uint256 supply = address(master) != address(0) ? master.totalSupply() : 0;
            //Nobody earns any GAME if everyone withdraws. If that's the case, all GAME goes to the treasury's daoFund.
            uint256 nextRPS = supply == 0 ? prevRPS : prevRPS.add(amount.mul(1e18).div(supply)); //Otherwise, GAME is distributed amongst those who have not yet burned their MASTER.

            if(supply == 0 && amount > 0)
            {
                _transfer(address(this), treasury, amount);
            }

            Snapshot memory newSnapshot = Snapshot({
            time: block.number,
            rewardReceived: amount,
            rewardPerShare: nextRPS
            });
            masterHistory.push(newSnapshot);
        }

        lastInitiateTime = block.timestamp;
        addedBalance = 0;
        //TODO: Hooks before + after
    }

    function initiate() external nonReentrant
    {
        require(block.timestamp > lastInitiateTime, "INIT"); //Already initiated this block.
        _initiate();
    }

    function onMintOrBurn(address pair) external
    {
        require(msg.sender == factory.buybackContract(), "OFBB"); //Only from buyback.
        //pendingMintRefund will be 0 if it is a burn (or if the person has no credits)
        if(pendingMintRefund[pair] != 0)
        {
            uint256 pairBalance = IUniswapV2Pair(pair).balanceOf(tx.origin);
            uint256 len = farms.length;
            for(uint256 i; i < len; i += 1)
            {
                IUniswapV2Farm farm = farms[i];
                pairBalance = pairBalance.add(farm.depositBalanceOf(pair, tx.origin));
            }
            if(pairBalance < lastPairBalance[pair][tx.origin])
            {
                //If they don't have >= lastPairBalance balance, assume the worst (they transferred their LP and then sold it) and remove all of their credits.
                //They can possibly screw themselves by breaking LP, then minting less LP right after, or lending out their LP. But people doing that is so rare that we can handle it on a case-by-case basis.
                emit CreditsTaken(tx.origin, credits[tx.origin]);
                lastPairBalance[pair][tx.origin] = 0;
                credits[tx.origin] = 0;
                gameLinkedToCredits[tx.origin] = 0;
            }
            else
            {
                lastPairBalance[pair][tx.origin] = pairBalance;
                credits[tx.origin] = credits[tx.origin].add(pendingMintRefund[pair]); //The one who initiates the mint gets the refund.
                gameLinkedToCredits[tx.origin] = gameLinkedToCredits[tx.origin].add(pendingMintLink[pair]); //The one who initiates the mint gets the refund.
                emit CreditsGiven(tx.origin, pendingMintRefund[pair]);
            }
            pendingMintRefund[pair] = 0;
            pendingMintLink[pair] = 0;
        }
    }

    //Liquidity is liquidity before the sell. Not recommended but can be done: Seller can be determined by tx.origin.
    function onSell(uint256 liquidity, uint256 amount, address to, address boughtToken, uint256 boughtLiquidity, uint256 boughtAmount) external nonReentrant returns (uint256[] memory taxIn, uint256[] memory taxOut, address[] memory taxTo)
    {
        require(msg.sender == factory.getPair(address(this), boughtToken), "Mismatching pair.");
        //Get tax.
        uint256 oldRevenue = revenue.sub(MathUpgradeable.min(revenue, canDecreaseAmount()));
        //Decrease revenue by the pending amount, then increase it.
        _increaseRevenue(amount);
        //Get tax.
        {
            uint256 taxAmount = taxAmountIn(oldRevenue, revenue, liquidity);
            if(taxAmount == 0) taxAmount = 1; //Avoid tax evasion via dust.
            uint256 toBeDistributed = taxAmount.mul(
            //350
                1000).div(10000); //TODO: Customization
            uint256 toDev = taxAmount.mul(1000).div(10000); //TODO: Customization
            uint256 toTreasury = taxAmount.sub(toBeDistributed).sub(toDev);
            //Send tax to the appropriate places.
            //Could push, but IDE would complain that the return values are not initialized.
            taxIn = new uint256[](3);
            taxIn[0] = toTreasury;
            taxIn[1] = toBeDistributed;
            taxIn[2] = toDev;
        }
        taxOut = new uint256[](3);
        //Could leave blank, but here for clarity
        taxOut[0] = 0;
        taxOut[1] = taxAmountOut(boughtToken, boughtAmount);
        taxOut[2] = 0;
        //Credits are removed already in _beforeTokenTransfer now. Also avoids the use of tx.origin here.
//        if(address(oracle) != address(0))
//        {
//            try oracle.updateIfPossible() {} catch {}
//            if(taxOut[1] > 0)
//            {
//                uint256 decimals = claimableTokens[claimableTokenIndex[boughtToken].sub(1)].decimals;
//                uint256 creditsEarned = oracle.getPrice(boughtToken).mul(boughtAmount).div((10)**(decimals));
//                creditsEarned = MathUpgradeable.min(creditsEarned, credits[tx.origin]);
//                credits[tx.origin] = credits[tx.origin].sub(creditsEarned);
//                totalCredits = totalCredits.sub(creditsEarned);
//                emit CreditsTaken(to, creditsEarned);
//            }
//        }
        taxTo = new address[](3);
        taxTo[0] = treasury;
        taxTo[1] = address(this);
        taxTo[2] = devFund;
        //TODO: Hooks before + after
    }

    function afterSellTax(uint256 liquidity, uint256 amount, address to, address boughtToken, uint256 boughtLiquidity, uint256 boughtAmount) external nonReentrant
    {
        require(msg.sender == factory.getPair(address(this), boughtToken), "Mismatching pair.");
        if(block.timestamp >= lastInitiateTime.add(30 days)) // gas savings
        {
            _initiate();
        }
    }

    function expectedBuyTax(uint256 liquidity, uint256 amount, address to, address soldToken, uint256 soldLiquidity, uint256 soldAmount) view external returns (uint256 taxOut, uint256 taxIn)
    {
        taxIn = 0;
        taxOut = 0;
    }
    function expectedSellTax(uint256 liquidity, uint256 amount, address to, address boughtToken, uint256 boughtLiquidity, uint256 boughtAmount) view external returns (uint256 taxIn, uint256 taxOut)
    {
        //Get tax.
        uint256 oldRevenue = revenue.sub(MathUpgradeable.min(revenue, canDecreaseAmount()));
        uint256 newRevenue = oldRevenue.add(amount);
        uint256 taxAmount = taxAmountIn(oldRevenue, newRevenue, liquidity);
        if(taxAmount == 0) taxAmount = 1;
        taxIn = taxAmount;
        taxOut = taxAmountOut(boughtToken, boughtAmount);
    }

    //Snapshot

    // =========== Snapshot getters

    function latestHolderSnapshotIndex() public view returns (uint256) {
        return holderHistory.length.sub(1);
    }

    function getLatestHolderSnapshot() internal view returns (Snapshot memory) {
        return holderHistory[latestHolderSnapshotIndex()];
    }

    function getLastHolderSnapshotIndexOf(address user) public view returns (uint256) {
        return lastHolderSnapshotIndex[user];
    }

    function getLastHolderSnapshotOf(address user) internal view returns (Snapshot memory) {
        return holderHistory[getLastHolderSnapshotIndexOf(user)];
    }

    function holderEarned(address user) public view returns (uint256) {
        uint256 latestRPS = getLatestHolderSnapshot().rewardPerShare;
        uint256 storedRPS = getLastHolderSnapshotOf(user).rewardPerShare;

        uint256 totalFarmAmount = 0;
        uint256 len = farms.length;
        for(uint256 i; i < len; i += 1)
        {
            IUniswapV2Farm farm = farms[i];
            if(user == address(farm)) return 0; //Redirect to non-farms.
            //Can't add reward balance because:
            //1. Emergency Withdraw makes it so those reward might not be yours anymore
            //2. Rewards aren't included in totalSupply until they are minted.
            //3. It would require a loop (at least the easiest way of doing it), leading to potential gas issues.
            totalFarmAmount = totalFarmAmount.add(farm.depositBalanceOf(address(this), user));
        }
        return balanceOf(user).add(totalFarmAmount).mul(latestRPS.sub(storedRPS)).div(1e18).add(holderRewardEarned[user]);
    }

    function latestLpSnapshotIndex(uint256 i) public view returns (uint256) {
        return lpHistory[i].length.sub(1);
    }

    function getLatestLpSnapshot(uint256 i) internal view returns (Snapshot memory) {
        return lpHistory[i][latestLpSnapshotIndex(i)];
    }

    function getLastLpSnapshotIndexOf(uint256 i, address user) public view returns (uint256) {
        return lastLpSnapshotIndex[i][user];
    }

    function getLastLpSnapshotOf(uint256 i, address user) internal view returns (Snapshot memory) {
        return lpHistory[i][getLastLpSnapshotIndexOf(i, user)];
    }

    function lpEarned(uint256 index, address user) public view returns (uint256) {
        uint256 latestRPS = getLatestLpSnapshot(index).rewardPerShare;
        uint256 storedRPS = getLastLpSnapshotOf(index, user).rewardPerShare;

        uint256 totalFarmAmount = 0;
        uint256 len = farms.length;
        for(uint256 i; i < len; i += 1)
        {
            IUniswapV2Farm farm = farms[i];
            if(user == address(farm)) return 0; //Redirect to non-farms.
            totalFarmAmount = totalFarmAmount.add(farm.depositBalanceOf(address(lpTokens[index]), user));
            //NOTE: MASTER also gets a piece of this pie, technically, in addition to its own pool.
            //MASTER is always staking this, so no need to put in exceptions for MASTER.
        }
        return lpTokens[index].balanceOf(user).add(totalFarmAmount).mul(latestRPS.sub(storedRPS)).div(1e18).add(lpRewardEarned[index][user]);
    }

    function latestMasterSnapshotIndex() public view returns (uint256) {
        return masterHistory.length.sub(1);
    }

    function getLatestMasterSnapshot() internal view returns (Snapshot memory) {
        return masterHistory[latestMasterSnapshotIndex()];
    }

    function getLastMasterSnapshotIndexOf(address user) public view returns (uint256) {
        return lastMasterSnapshotIndex[user];
    }

    function getLastMasterSnapshotOf(address user) internal view returns (Snapshot memory) {
        return masterHistory[getLastMasterSnapshotIndexOf(user)];
    }

    function masterEarned(address user) public view returns (uint256) {
        uint256 latestRPS = getLatestMasterSnapshot().rewardPerShare;
        uint256 storedRPS = getLastMasterSnapshotOf(user).rewardPerShare;

        uint256 totalFarmAmount = 0;
        uint256 len = farms.length;
        for(uint256 i; i < len; i += 1)
        {
            IUniswapV2Farm farm = farms[i];
            if(user == address(farm)) return 0; //Redirect to non-farms.
            totalFarmAmount = totalFarmAmount.add(farm.depositBalanceOf(address(master), user));
        }

        uint256 balance = address(master) != address(0) ?  master.balanceOf(user) : 0;
        return balance.mul(latestRPS.sub(storedRPS)).div(1e18).add(masterRewardEarned[user]);
    }

    //Each token (GAME, LPs, MASTER) MUST call updateReward in _beforeTokenTransfer, else you risk people biting more than they can chew.
    function _updateReward(address user) internal
    {
        uint256 latestHolderIndex = latestHolderSnapshotIndex();
        if(lastHolderSnapshotIndex[user] == latestHolderIndex) return; //This will not cover new LP, but it shouldn't matter too much because there will be 0 earnings at that point anyways. The gas savings are more important.
        holderRewardEarned[user] = holderEarned(user);
        lastHolderSnapshotIndex[user] = latestHolderIndex;
        uint256 len = lpTokens.length;
        for(uint256 i; i < len; i += 1)
        {
            lpRewardEarned[i][user] = lpEarned(i, user);
            lastLpSnapshotIndex[i][user] = latestLpSnapshotIndex(i);
        }
        masterRewardEarned[user] = masterEarned(user);
        lastMasterSnapshotIndex[user] = latestMasterSnapshotIndex();
        //TODO: Hooks before + after
    }

    function updateReward(address user) external nonReentrant
    {
        _updateReward(user);
    }

    function totalEarned(address user) public view returns (uint256)
    {
        uint256 reward = holderEarned(user).add(masterEarned(user));
        uint256 len = lpTokens.length;
        for(uint256 i; i < len; i += 1)
        {
            reward = reward.add(lpEarned(i, user));
        }
        return reward;
    }

    function claimReward() nonReentrant public
    {
        //Checks
        //Effects
        _updateReward(msg.sender); //Has safe "interactions": Only external calls are view functions.
        uint256 reward = holderRewardEarned[msg.sender].add(masterRewardEarned[msg.sender]);
        holderRewardEarned[msg.sender] = 0;
        masterRewardEarned[msg.sender] = 0;
        uint256 len = lpTokens.length;
        for(uint256 i; i < len; i += 1)
        {
            reward = reward.add(lpRewardEarned[i][msg.sender]);
            lpRewardEarned[i][msg.sender] = 0;
        }
        //Interactions
        if (reward > 0) {
            //totalGameUnclaimed = totalGameUnclaimed.sub(reward);
            if(address(master) != address(0))
            {
                master.onClaimReward(msg.sender, reward);
            }
            _transfer(address(this), msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
        //TODO: Hooks before + after
    }

    function getPrice() public view returns (uint256 gamePrice) {
        try IOracleV2(oracle).getPrice(address(this)) returns (uint256 price) {
            return price;
        } catch {
            revert("CF"); //GAME: failed to consult GAME price from the oracle
        }
    }

    function getUpdatedPrice() public view returns (uint256 _gamePrice) {
        try IOracleV2(oracle).getUpdatedPrice(address(this)) returns (uint256 price) {
            return price;
        } catch {
            revert("CF"); //GAME: failed to consult GAME price from the oracle
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal initializer {
    }
    using SafeMathUpgradeable for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IOracleV2 {
    function update() external;

    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut);

    function twap(address _token, uint256 _amountIn) external view returns (uint144 _amountOut);

    function updateIfPossible() external;

    function getPrice(address _token) external view returns (uint256);
    function getUpdatedPrice(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ITreasury {
    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getGamePrice() external view returns (uint256);

    function gamePriceOne() external view returns (uint256);
    function gamePriceCeiling() external view returns (uint256);
    function initialized() external view returns (bool);
    function daoFund() external view returns (address);

    function buyBonds(uint256 amount, uint256 targetPrice) external;

    function redeemBonds(uint256 amount, uint256 targetPrice) external;
}

pragma solidity 0.6.12;
import "./owner/OperatorUpgradeable.sol";

contract AuthorizableUpgradeable is OperatorUpgradeable {
    mapping(address => bool) public authorized;

    function __Authorizable_init() internal initializer {
        __Operator_init();
    }

    function __Authorizable_init_unchained() internal initializer {
    }

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender || operator() == msg.sender, "caller is not authorized");
        _;
    }

    function addAuthorized(address _toAdd) public onlyOwner {
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) public onlyOwner {
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IDistributable {
    function getRequiredAllocation() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function devFund() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);
    function router() external view returns (address);
    function createPairAdmin() external view returns (address);
    function createPairAdminOnly() external view returns (bool);
    function tempLock() external view returns (bool);
    function GAME() external view returns (address);
    function useFee() external view returns (bool);
    function buybackContract() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function hookedTokens(address) external view returns (bool);

    function createPair(address tokenA, address tokenB, bool burnBuybackToken, address[] memory buybackRouteA, address[] memory buybackRouteB) external returns (address pair);

    function setFeeTo(address) external;
    function setDevFund(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
    function setRouter(address) external;
    function setCreatePairAdmin(address) external;
    function setCreatePairAdminOnly(bool) external;
    function changeHookedToken(address,bool) external;
    function setBuybackContract(address) external;
    function buyback() external;
    function setBuybackRoute(address pair, bool _burnBuybackToken, address[] memory _buybackRoute0, address[] memory _buybackRoute1) external;
}

// SPDX-License-Identifier: GPL-3.0

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
    function isGameLp() external view returns (bool);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function burnBuybackToken() external view returns (bool);
    function getBuybackRoute0() external view returns (address[] memory);
    function buybackTokenIndex() external view returns (uint256);
    function getBuybackRoute1() external view returns (address[] memory);
    function setBuybackRoute(bool _burnBuybackToken, address[] memory _buybackRoute0, address[] memory _buybackRoute1) external;

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
pragma solidity 0.6.12;
interface IMasterV2 is IERC20Upgradeable {
  function deposit ( uint256 amount, uint256 lockTime ) external;
  function maxLockTime (  ) external view returns ( uint256 );
  function minLockTime (  ) external view returns ( uint256 );
  function onClaimReward ( address to, uint256 reward ) external;
  function penaltyTime (  ) external view returns ( uint256 );
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Farm {
    function depositBalanceOf(address token, address user) view external returns (uint256);
    function depositOnBehalfOf ( address giftee, uint256 _pid, uint256 _amount ) external;
    function withdrawOnBehalfOf ( address giftee, uint256 _pid, uint256 _amount ) external;
    function emergencyWithdrawOnBehalfOf ( address giftee, uint256 _pid ) external;
    function poolNumber ( address giftee ) view external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract OperatorUpgradeable is OwnableUpgradeable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    function __Operator_init() internal initializer {
        __Ownable_init();
        __Operator_init_unchained();
    }

    function __Operator_init_unchained() internal initializer {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner { //For the new GAME, we need to change minting privs via owner, not operator.
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}