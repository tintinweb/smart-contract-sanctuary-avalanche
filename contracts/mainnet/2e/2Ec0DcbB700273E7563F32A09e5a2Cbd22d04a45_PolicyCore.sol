// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
    *******         **********     ***********     *****     ***********
    *      *        *              *                 *       *
    *        *      *              *                 *       *
    *         *     *              *                 *       *
    *         *     *              *                 *       *
    *         *     **********     *       *****     *       ***********
    *         *     *              *         *       *                 *
    *         *     *              *         *       *                 *
    *        *      *              *         *       *                 *
    *      *        *              *         *       *                 *
    *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.10;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {StringsUtils} from "../libraries/StringsUtils.sol";
import {Ownable} from "../utils/Ownable.sol";
import {IERC20Decimals} from "../utils/interfaces/IERC20Decimals.sol";
import {IPriceGetter} from "./interfaces/IPriceGetter.sol";
import {INaughtyFactory} from "./interfaces/INaughtyFactory.sol";
import {INPPolicyToken} from "./interfaces/INPPolicyToken.sol";
import {INaughtyRouter} from "./interfaces/INaughtyRouter.sol";

/**
 * @title  PolicyCore
 * @notice Core logic of Naughty Price Product
 *         Preset:
 *              (Done in the naughtyFactory contract)
 *              1. Deploy policyToken contract
 *              2. Deploy policyToken-Stablecoin pool contract
 *         User Interaction:
 *              1. Deposit Stablecoin and mint PolicyTokens
 *              2. Redeem their Stablecoin and burn the PolicyTokens (before settlement)
 *              3. Claim for payout with PolicyTokens (after settlement)
 *         PolicyTokens are minted with the ratio 1:1 to Stablecoin
 *         The PolicyTokens are traded in the pool with CFMM (xy=k)
 *         When the event happens, a PolicyToken can be burned for claiming 1 Stablecoin.
 *         When the event does not happen, the PolicyToken depositors can
 *         redeem their 1 deposited Stablecoin
 * @dev    Most of the functions to be called from outside will use the name of policyToken
 *         rather than the address (easy to read).
 *         Other variables or functions still use address to index.
 *         The rule of policyToken naming is:
 *              Original Token Name(with decimals) + Strike Price + Lower or Higher + Date
 *         E.g.  AVAX_30.0_L_2101, BTC_30000.0_L_2102, ETH_8000.0_H_2109
 *         (the original name need to be the same as in the chainlink oracle)
 *         There are three decimals for a policy token:
 *              1. Name decimals: Only for generating the name of policyToken
 *              2. Token decimals: The decimals of the policyToken
 *                 (should be the same as the paired stablecoin)
 *              3. Price decimals: Always 18. The oracle result will be transferred for settlement
 */

contract PolicyCore is Ownable {
    using StringsUtils for uint256;
    using SafeERC20 for IERC20;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Factory contract, responsible for deploying new contracts
    INaughtyFactory public factory;

    // Oracle contract, responsible for getting the final price
    IPriceGetter public priceGetter;

    // Lottery address
    address public lottery;

    // Income sharing contract address
    address public incomeSharing;

    // Naughty Router contract address
    address public naughtyRouter;

    // Contract for initial liquidity matching
    address public ILMContract;

    // Income to lottery ratio (max 10)
    uint256 public toLottery;

    struct PolicyTokenInfo {
        address policyTokenAddress;
        bool isCall;
        uint256 nameDecimals; // decimals of the name generation
        uint256 tokenDecimals; // decimals of the policy token
        uint256 strikePrice;
        uint256 deadline;
        uint256 settleTimestamp;
    }
    // Policy token name => Policy token information
    mapping(string => PolicyTokenInfo) public policyTokenInfoMapping;

    // Policy token address => Policy token name
    mapping(address => string) public policyTokenAddressToName;

    // Policy token name list
    string[] public allPolicyTokens;

    // Stablecoin address => Supported or not
    mapping(address => bool) public supportedStablecoin;

    // Policy token address => Stablecoin address
    mapping(address => address) public whichStablecoin;

    // PolicyToken => Strike Token (e.g. AVAX30L202101 address => AVAX address)
    mapping(address => string) policyTokenToOriginal;

    // User Address => Token Address => User Quota Amount
    mapping(address => mapping(address => uint256)) userQuota;

    // Policy token address => All the depositors for this round
    // (store all the depositors in an array)
    mapping(address => address[]) public allDepositors;

    struct SettlementInfo {
        uint256 price;
        bool isHappened;
        bool alreadySettled;
        uint256 currentDistributionIndex;
    }
    // Policy token address => Settlement result information
    mapping(address => SettlementInfo) public settleResult;

    mapping(address => uint256) public pendingIncomeToLottery;
    mapping(address => uint256) public pendingIncomeToSharing;

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Events ******************************************** //
    // ---------------------------------------------------------------------------------------- //

    event LotteryChanged(address oldLotteryAddress, address newLotteryAddress);
    event IncomeSharingChanged(
        address oldIncomeSharing,
        address newIncomeSharing
    );
    event NaughtyRouterChanged(address oldRouter, address newRouter);
    event ILMChanged(address oldILM, address newILM);
    event IncomeToLotteryChanged(uint256 oldToLottery, uint256 newToLottery);
    event PolicyTokenDeployed(
        string tokenName,
        address tokenAddress,
        uint256 tokenDecimals,
        uint256 deadline,
        uint256 settleTimestamp
    );
    event PoolDeployed(
        address poolAddress,
        address policyTokenAddress,
        address stablecoin
    );
    event PoolDeployedWithInitialLiquidity(
        address poolAddress,
        address policyTokenAddress,
        address stablecoin,
        uint256 initLiquidityA,
        uint256 initLiquidityB
    );
    event Deposit(
        address userAddress,
        string policyTokenName,
        address stablecoin,
        uint256 amount
    );
    event DelegateDeposit(
        address payerAddress,
        address userAddress,
        string policyTokenName,
        address stablecoin,
        uint256 amount
    );
    event Redeem(
        address userAddress,
        string policyTokenName,
        address stablecoin,
        uint256 amount
    );
    event RedeemAfterSettlement(
        address userAddress,
        string policyTokenName,
        address stablecoin,
        uint256 amount
    );
    event FinalResultSettled(
        string _policyTokenName,
        uint256 price,
        bool isHappened
    );
    event NewStablecoinAdded(address _newStablecoin);
    event PolicyTokensSettledForUsers(
        string policyTokenName,
        address stablecoin,
        uint256 startIndex,
        uint256 stopIndex
    );

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Constructor, for some addresses
     * @param _usdt USDT.e is the first stablecoin supported in the pool
     * @param _factory Address of naughty factory
     * @param _priceGetter Address of the oracle contract
     */
    constructor(
        address _usdt,
        address _factory,
        address _priceGetter
    ) Ownable(msg.sender) {
        // Add the first stablecoin supported
        supportedStablecoin[_usdt] = true;

        // Initialize the interfaces
        factory = INaughtyFactory(_factory);
        priceGetter = IPriceGetter(_priceGetter);

        // 20% to lottery, 80% to income sharing
        toLottery = 2;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Check if this stablecoin is supported
     * @param _stablecoin Stablecoin address
     */
    modifier validStablecoin(address _stablecoin) {
        require(
            supportedStablecoin[_stablecoin] == true,
            "Do not support this stablecoin currently"
        );
        _;
    }

    /**
     * @notice Check whether the policy token is paired with this stablecoin
     * @param _policyTokenName Policy token name
     * @param _stablecoin Stablecoin address
     */
    modifier validPolicyTokenWithStablecoin(
        string memory _policyTokenName,
        address _stablecoin
    ) {
        address policyTokenAddress = findAddressbyName(_policyTokenName);
        require(
            whichStablecoin[policyTokenAddress] == _stablecoin,
            "Invalid policytoken with stablecoin"
        );
        _;
    }

    /**
     * @notice Check if the policy token has been deployed, used when deploying pools
     * @param _policyTokenName Name of the policy token inside the pair
     */
    modifier deployedPolicy(string memory _policyTokenName) {
        require(
            policyTokenInfoMapping[_policyTokenName].policyTokenAddress !=
                address(0),
            "This policy token has not been deployed, please deploy it first"
        );
        _;
    }

    /**
     * @notice Deposit/Redeem/Swap only before deadline
     * @dev Each pool will also have this deadline
     *      That needs to be set inside naughtyFactory
     * @param _policyTokenName Name of the policy token
     */
    modifier beforeDeadline(string memory _policyTokenName) {
        uint256 deadline = policyTokenInfoMapping[_policyTokenName].deadline;
        require(
            block.timestamp <= deadline,
            "Can not deposit/redeem, has passed the deadline"
        );
        _;
    }

    /**
     * @notice Can only settle the result after the "_settleTimestamp"
     * @param _policyTokenName Name of the policy token
     */
    modifier afterSettlement(string memory _policyTokenName) {
        uint256 settleTimestamp = policyTokenInfoMapping[_policyTokenName]
            .settleTimestamp;
        require(
            block.timestamp >= settleTimestamp,
            "Can not settle/claim, have not reached settleTimestamp"
        );
        _;
    }

    /**
     * @notice Avoid multiple settlements
     * @param _policyTokenName Name of the policy token
     */
    modifier notAlreadySettled(string memory _policyTokenName) {
        address policyTokenAddress = findAddressbyName(_policyTokenName);
        require(
            settleResult[policyTokenAddress].alreadySettled == false,
            "This policy has already been settled"
        );
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Find the token address by its name
     * @param _policyTokenName Name of the policy token (e.g. "AVAX_30_L_2103")
     * @return policyTokenAddress Address of the policy token
     */
    function findAddressbyName(string memory _policyTokenName)
        public
        view
        returns (address policyTokenAddress)
    {
        policyTokenAddress = policyTokenInfoMapping[_policyTokenName]
            .policyTokenAddress;

        require(policyTokenAddress != address(0), "Policy token not found");
    }

    /**
     * @notice Find the token name by its address
     * @param _policyTokenAddress Address of the policy token
     * @return policyTokenName Name of the policy token
     */
    function findNamebyAddress(address _policyTokenAddress)
        public
        view
        returns (string memory policyTokenName)
    {
        policyTokenName = policyTokenAddressToName[_policyTokenAddress];

        require(bytes(policyTokenName).length > 0, "Policy name not found");
    }

    /**
     * @notice Find the token information by its name
     * @param _policyTokenName Name of the policy token (e.g. "AVAX30L202103")
     * @return policyTokenInfo PolicyToken detail information
     */
    function getPolicyTokenInfo(string memory _policyTokenName)
        public
        view
        returns (PolicyTokenInfo memory)
    {
        return policyTokenInfoMapping[_policyTokenName];
    }

    /**
     * @notice Get a user's quota for a certain policy token
     * @param _user Address of the user to be checked
     * @param _policyTokenAddress Address of the policy token
     * @return _quota User's quota result
     */
    function getUserQuota(address _user, address _policyTokenAddress)
        external
        view
        returns (uint256 _quota)
    {
        _quota = userQuota[_user][_policyTokenAddress];
    }

    /**
     * @notice Get the information about all the tokens
     * @dev Include all active&expired tokens
     * @return tokensInfo Token information list
     */
    function getAllTokens() external view returns (PolicyTokenInfo[] memory) {
        uint256 length = allPolicyTokens.length;
        PolicyTokenInfo[] memory tokensInfo = new PolicyTokenInfo[](length);

        for (uint256 i = 0; i < length; i++) {
            tokensInfo[i] = policyTokenInfoMapping[allPolicyTokens[i]];
        }

        return tokensInfo;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Add a new supported stablecoin
     * @param _newStablecoin Address of the new stablecoin
     */
    function addStablecoin(address _newStablecoin) external onlyOwner {
        supportedStablecoin[_newStablecoin] = true;
        emit NewStablecoinAdded(_newStablecoin);
    }

    /**
     * @notice Change the address of lottery
     * @param _lotteryAddress Address of the new lottery
     */
    function setLottery(address _lotteryAddress) external onlyOwner {
        emit LotteryChanged(lottery, _lotteryAddress);
        lottery = _lotteryAddress;
    }

    /**
     * @notice Change the address of emergency pool
     * @param _incomeSharing Address of the new incomeSharing
     */
    function setIncomeSharing(address _incomeSharing) external onlyOwner {
        emit IncomeSharingChanged(incomeSharing, _incomeSharing);
        incomeSharing = _incomeSharing;
    }

    /**
     * @notice Change the address of naughty router
     * @param _router Address of the new naughty router
     */
    function setNaughtyRouter(address _router) external onlyOwner {
        emit NaughtyRouterChanged(naughtyRouter, _router);
        naughtyRouter = _router;
    }

    function setILMContract(address _ILM) external onlyOwner {
        emit ILMChanged(ILMContract, _ILM);
        ILMContract = _ILM;
    }

    function setIncomeToLottery(uint256 _toLottery) external onlyOwner {
        require(_toLottery <= 10, "Max 10");
        emit IncomeToLotteryChanged(toLottery, _toLottery);
        toLottery = _toLottery;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Deploy a new policy token and return the token address
     * @dev Only the owner can deploy new policy token
     *      The name form is like "AVAX_50_L_2203" and is built inside the contract.
     * @param _tokenName Name of the original token (e.g. AVAX, BTC, ETH...)
     * @param _stablecoin Address of the stablecoin (Just for check decimals here)
     * @param _isCall The policy is for higher or lower than the strike price (call / put)
     * @param _nameDecimals Decimals of this token's name (0~18)
     * @param _tokenDecimals Decimals of this token's value (0~18) (same as paired stablecoin)
     * @param _strikePrice Strike price of the policy (have already been transferred with 1e18)
     * @param _round Round of the token (e.g. 2203 -> expired at 22 March)
     * @param _deadline Deadline of this policy token (deposit / redeem / swap)
     * @param _settleTimestamp Can settle after this timestamp (for oracle)
     */
    function deployPolicyToken(
        string memory _tokenName,
        address _stablecoin,
        bool _isCall,
        uint256 _nameDecimals,
        uint256 _tokenDecimals,
        uint256 _strikePrice,
        string memory _round,
        uint256 _deadline,
        uint256 _settleTimestamp
    ) external onlyOwner {
        require(
            _nameDecimals <= 18 && _tokenDecimals <= 18,
            "Too many decimals"
        );
        require(
            IERC20Decimals(_stablecoin).decimals() == _tokenDecimals,
            "Decimals not paired"
        );

        require(_deadline > block.timestamp, "Wrong deadline");
        require(_settleTimestamp >= _deadline, "Wrong settleTimestamp");

        // Generate the policy token name
        string memory policyTokenName = _generateName(
            _tokenName,
            _nameDecimals,
            _strikePrice,
            _isCall,
            _round
        );
        // Deploy a new policy token by the factory contract
        address policyTokenAddress = factory.deployPolicyToken(
            policyTokenName,
            _tokenDecimals
        );

        // Store the policyToken information in the mapping
        policyTokenInfoMapping[policyTokenName] = PolicyTokenInfo(
            policyTokenAddress,
            _isCall,
            _nameDecimals,
            _tokenDecimals,
            _strikePrice,
            _deadline,
            _settleTimestamp
        );

        // Keep the record from policy token to original token
        policyTokenToOriginal[policyTokenAddress] = _tokenName;

        // Record the address to name mapping
        policyTokenAddressToName[policyTokenAddress] = policyTokenName;

        // Push the policytokenName into the list
        allPolicyTokens.push(policyTokenName);

        emit PolicyTokenDeployed(
            policyTokenName,
            policyTokenAddress,
            _tokenDecimals,
            _deadline,
            _settleTimestamp
        );
    }

    /**
     * @notice Deploy a new pair (pool)
     * @param _policyTokenName Name of the policy token
     * @param _stablecoin Address of the stable coin
     * @param _poolDeadline Swapping deadline of the pool (normally the same as the token's deadline)
     * @param _feeRate Fee rate given to LP holders
     */
    function deployPool(
        string memory _policyTokenName,
        address _stablecoin,
        uint256 _poolDeadline,
        uint256 _feeRate
    )
        external
        validStablecoin(_stablecoin)
        deployedPolicy(_policyTokenName)
        returns (address)
    {
        require(
            msg.sender == owner() || msg.sender == ILMContract,
            "Only owner or ILM"
        );

        require(_poolDeadline > block.timestamp, "Wrong deadline");
        require(
            _poolDeadline == policyTokenInfoMapping[_policyTokenName].deadline,
            "Policy token and pool deadline not the same"
        );
        address policyTokenAddress = findAddressbyName(_policyTokenName);

        address poolAddress = _deployPool(
            policyTokenAddress,
            _stablecoin,
            _poolDeadline,
            _feeRate
        );

        emit PoolDeployed(poolAddress, policyTokenAddress, _stablecoin);

        return poolAddress;
    }

    /**
     * @notice Deposit stablecoins and get policy tokens
     * @param _policyTokenName Name of the policy token
     * @param _stablecoin Address of the stable coin
     * @param _amount Amount of stablecoin
     */
    function deposit(
        string memory _policyTokenName,
        address _stablecoin,
        uint256 _amount
    )
        public
        beforeDeadline(_policyTokenName)
        validPolicyTokenWithStablecoin(_policyTokenName, _stablecoin)
    {
        _deposit(_policyTokenName, _stablecoin, _amount, msg.sender);
    }

    /**
     * @notice Delegate deposit (deposit and mint for other addresses)
     * @dev Only called by the router contract
     * @param _policyTokenName Name of the policy token
     * @param _stablecoin Address of the sable coin
     * @param _amount Amount of stablecoin
     * @param _user Address to receive the policy tokens
     */
    function delegateDeposit(
        string memory _policyTokenName,
        address _stablecoin,
        uint256 _amount,
        address _user
    )
        external
        beforeDeadline(_policyTokenName)
        validPolicyTokenWithStablecoin(_policyTokenName, _stablecoin)
    {
        require(
            msg.sender == naughtyRouter,
            "Only the router contract can delegate"
        );

        _deposit(_policyTokenName, _stablecoin, _amount, _user);

        emit DelegateDeposit(
            msg.sender,
            _user,
            _policyTokenName,
            _stablecoin,
            _amount
        );
    }

    /**
     * @notice Burn policy tokens and redeem stablecoins
     * @dev Redeem happens before the deadline and is different from claim/settle
     * @param _policyTokenName Name of the policy token
     * @param _stablecoin Address of the stablecoin
     * @param _amount Amount to redeem
     */
    function redeem(
        string memory _policyTokenName,
        address _stablecoin,
        uint256 _amount
    )
        public
        beforeDeadline(_policyTokenName)
        validPolicyTokenWithStablecoin(_policyTokenName, _stablecoin)
    {
        address policyTokenAddress = findAddressbyName(_policyTokenName);

        // Check if the user has enough quota (quota is only for those who mint policy tokens)
        require(
            userQuota[msg.sender][policyTokenAddress] >= _amount,
            "User's quota not sufficient"
        );

        // Update quota
        userQuota[msg.sender][policyTokenAddress] -= _amount;

        // Transfer back the stablecoin
        IERC20(_stablecoin).safeTransfer(msg.sender, _amount);

        // Burn the policy tokens
        INPPolicyToken policyToken = INPPolicyToken(policyTokenAddress);
        policyToken.burn(msg.sender, _amount);

        emit Redeem(msg.sender, _policyTokenName, _stablecoin, _amount);
    }

    /**
     * @notice Redeem policy tokens and get stablecoins by the user himeself
     * @param _policyTokenName Name of the policy token
     * @param _stablecoin Address of the stablecoin
     */
    function redeemAfterSettlement(
        string memory _policyTokenName,
        address _stablecoin
    )
        public
        afterSettlement(_policyTokenName)
        validPolicyTokenWithStablecoin(_policyTokenName, _stablecoin)
    {
        address policyTokenAddress = findAddressbyName(_policyTokenName);

        // Copy to memory (will not change the result)
        SettlementInfo memory result = settleResult[policyTokenAddress];

        // Must have got the final price
        require(
            result.price != 0 && result.alreadySettled,
            "Have not got the oracle result"
        );

        // The event must be "not happend"
        require(
            result.isHappened == false,
            "Only call this function when the event does not happen"
        );

        uint256 quota = userQuota[msg.sender][policyTokenAddress];
        // User must have quota because this is for depositors when event not happens
        require(
            quota > 0,
            "No quota, you did not deposit and mint policy tokens before"
        );

        // Charge 1% Fee when redeem / claim
        uint256 amountWithFee = (quota * 990) / 1000;
        uint256 amountToCollect = quota - amountWithFee;

        pendingIncomeToLottery[_stablecoin] +=
            (amountToCollect * toLottery) /
            10;
        pendingIncomeToSharing[_stablecoin] +=
            amountToCollect -
            (amountToCollect * toLottery) /
            10;

        // Send back stablecoins directly
        IERC20(_stablecoin).safeTransfer(msg.sender, amountWithFee);

        // Delete the userQuota storage
        delete userQuota[msg.sender][policyTokenAddress];

        emit RedeemAfterSettlement(
            msg.sender,
            _policyTokenName,
            _stablecoin,
            amountWithFee
        );
    }

    /**
     * @notice Claim a payoff based on policy tokens
     * @dev It is done after result settlement and only if the result is true
     * @param _policyTokenName Name of the policy token
     * @param _stablecoin Address of the stable coin
     * @param _amount Amount of stablecoin
     */
    function claim(
        string memory _policyTokenName,
        address _stablecoin,
        uint256 _amount
    )
        public
        afterSettlement(_policyTokenName)
        validPolicyTokenWithStablecoin(_policyTokenName, _stablecoin)
    {
        address policyTokenAddress = findAddressbyName(_policyTokenName);

        // Copy to memory (will not change the result)
        SettlementInfo memory result = settleResult[policyTokenAddress];

        // Check if we have already settle the final price
        require(
            result.price != 0 && result.alreadySettled,
            "Have not got the oracle result"
        );

        // Check if the event happens
        require(
            result.isHappened,
            "The result does not happen, you can not claim"
        );

        // Charge 1% fee
        uint256 amountWithFee = (_amount * 990) / 1000;
        uint256 amountToCollect = _amount - amountWithFee;

        // Update pending income record
        pendingIncomeToLottery[_stablecoin] +=
            (amountToCollect * toLottery) /
            10;
        pendingIncomeToSharing[_stablecoin] +=
            amountToCollect -
            (amountToCollect * toLottery) /
            10;

        IERC20(_stablecoin).safeTransfer(msg.sender, amountWithFee);

        // Users must have enough policy tokens to claim
        INPPolicyToken policyToken = INPPolicyToken(policyTokenAddress);

        // Burn the policy tokens
        policyToken.burn(msg.sender, _amount);
    }

    /**
     * @notice Get the final price from the PriceGetter contract
     * @param _policyTokenName Name of the policy token
     */
    function settleFinalResult(string memory _policyTokenName)
        public
        afterSettlement(_policyTokenName)
        notAlreadySettled(_policyTokenName)
    {
        address policyTokenAddress = findAddressbyName(_policyTokenName);

        SettlementInfo storage result = settleResult[policyTokenAddress];

        // Get the strike token name
        string memory originalTokenName = policyTokenToOriginal[
            policyTokenAddress
        ];

        // Get the final price from oracle
        uint256 price = IPriceGetter(priceGetter).getLatestPrice(
            originalTokenName
        );

        // Record the price
        result.alreadySettled = true;
        result.price = price;

        PolicyTokenInfo memory policyTokenInfo = policyTokenInfoMapping[
            _policyTokenName
        ];

        // Get the final result
        bool situationT1 = (price >= policyTokenInfo.strikePrice) &&
            policyTokenInfo.isCall;
        bool situationT2 = (price <= policyTokenInfo.strikePrice) &&
            !policyTokenInfo.isCall;

        bool isHappened = (situationT1 || situationT2) ? true : false;

        // Record the result
        result.isHappened = isHappened;

        emit FinalResultSettled(_policyTokenName, price, isHappened);
    }

    /**
     * @notice Settle the policies for the users when insurance events do not happen
     *         Funds are automatically distributed back to the depositors
     * @dev    Take care of the gas cost and can use the _startIndex and _stopIndex to control the size
     * @param _policyTokenName Name of policy token
     * @param _stablecoin Address of stablecoin
     * @param _startIndex Settlement start index
     * @param _stopIndex Settlement stop index
     */
    function settleAllPolicyTokens(
        string memory _policyTokenName,
        address _stablecoin,
        uint256 _startIndex,
        uint256 _stopIndex
    ) public onlyOwner {
        address policyTokenAddress = findAddressbyName(_policyTokenName);

        // Copy to memory (will not change the result)
        SettlementInfo memory result = settleResult[policyTokenAddress];

        // Must have got the final price
        require(
            result.price != 0 && result.alreadySettled == true,
            "Have not got the oracle result"
        );

        // The event must be "not happend"
        require(
            result.isHappened == false,
            "Only call this function when the event does not happen"
        );

        // Store the amount to collect to lottery and emergency pool
        uint256 amountToCollect = 0;

        // Length of all depositors for this policy token
        uint256 length = allDepositors[policyTokenAddress].length;

        require(
            result.currentDistributionIndex <= length,
            "Have distributed all"
        );

        // Settle the policies in [_startIndex, _stopIndex)
        if (_startIndex == 0 && _stopIndex == 0) {
            amountToCollect += _settlePolicy(
                policyTokenAddress,
                _stablecoin,
                0,
                length
            );

            // Update the distribution index for this policy token
            settleResult[policyTokenAddress].currentDistributionIndex = length;

            // Update pending income record
            pendingIncomeToLottery[_stablecoin] +=
                (amountToCollect * toLottery) /
                10;
            pendingIncomeToSharing[_stablecoin] +=
                amountToCollect -
                (amountToCollect * toLottery) /
                10;

            emit PolicyTokensSettledForUsers(
                _policyTokenName,
                _stablecoin,
                0,
                length
            );
        } else {
            require(
                result.currentDistributionIndex == _startIndex,
                "You need to start from the last distribution point"
            );
            require(_stopIndex < length, "Invalid stop index");

            amountToCollect += _settlePolicy(
                policyTokenAddress,
                _stablecoin,
                _startIndex,
                _stopIndex
            );

            // Update the distribution index for this policy token
            settleResult[policyTokenAddress]
                .currentDistributionIndex = _stopIndex;

            // Update pending income record
            pendingIncomeToLottery[_stablecoin] +=
                (amountToCollect * toLottery) /
                10;
            pendingIncomeToSharing[_stablecoin] +=
                amountToCollect -
                (amountToCollect * toLottery) /
                10;

            emit PolicyTokensSettledForUsers(
                _policyTokenName,
                _stablecoin,
                _startIndex,
                _stopIndex
            );
        }
    }

    /**
     * @notice Collect the income
     * @dev Can be done by anyone, only when there is some income to be distributed
     * @param _stablecoin Address of stablecoin
     */
    function collectIncome(address _stablecoin) public {
        require(
            lottery != address(0) && incomeSharing != address(0),
            "Please set the lottery & incomeSharing address"
        );

        uint256 amountToLottery = pendingIncomeToLottery[_stablecoin];
        uint256 amountToSharing = pendingIncomeToSharing[_stablecoin];
        require(
            amountToLottery > 0 || amountToSharing > 0,
            "No pending income"
        );

        IERC20(_stablecoin).safeTransfer(lottery, amountToLottery);
        IERC20(_stablecoin).safeTransfer(incomeSharing, amountToSharing);
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Internal Functions ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Finish deploying a pool
     * @param _policyTokenAddress Address of the policy token
     * @param _stablecoin Address of the stable coin
     * @param _poolDeadline Swapping deadline of the pool (normally the same as the token's deadline)
     * @param _feeRate Fee rate given to LP holders
     * @return poolAddress Address of the pool
     */
    function _deployPool(
        address _policyTokenAddress,
        address _stablecoin,
        uint256 _poolDeadline,
        uint256 _feeRate
    ) internal returns (address) {
        // Deploy a new pool (policyToken <=> stablecoin)
        address poolAddress = factory.deployPool(
            _policyTokenAddress,
            _stablecoin,
            _poolDeadline,
            _feeRate
        );

        // Record the mapping
        whichStablecoin[_policyTokenAddress] = _stablecoin;

        return poolAddress;
    }

    /**
     * @notice Finish Deposit
     * @param _policyTokenName Name of the policy token
     * @param _stablecoin Address of the sable coin
     * @param _amount Amount of stablecoin
     * @param _user Address to receive the policy tokens
     */
    function _deposit(
        string memory _policyTokenName,
        address _stablecoin,
        uint256 _amount,
        address _user
    ) internal {
        address policyTokenAddress = findAddressbyName(_policyTokenName);

        // If this is the first deposit, store the user address
        if (userQuota[_user][policyTokenAddress] == 0) {
            allDepositors[policyTokenAddress].push(_user);
        }

        // Update the user quota
        userQuota[_user][policyTokenAddress] += _amount;

        // Transfer stablecoins to this contract
        IERC20(_stablecoin).safeTransferFrom(_user, address(this), _amount);

        INPPolicyToken policyToken = INPPolicyToken(policyTokenAddress);

        // Mint new policy tokens
        policyToken.mint(_user, _amount);

        emit Deposit(_user, _policyTokenName, _stablecoin, _amount);
    }

    /**
     * @notice Settle the policy when the event does not happen
     * @param _policyTokenAddress Address of policy token
     * @param _stablecoin Address of stable coin
     * @param _start Start index
     * @param _stop Stop index
     */
    function _settlePolicy(
        address _policyTokenAddress,
        address _stablecoin,
        uint256 _start,
        uint256 _stop
    ) internal returns (uint256 amountRemaining) {
        for (uint256 i = _start; i < _stop; i++) {
            address user = allDepositors[_policyTokenAddress][i];
            uint256 amount = userQuota[user][_policyTokenAddress];
            uint256 amountWithFee = (amount * 990) / 1000;

            if (amountWithFee > 0) {
                IERC20(_stablecoin).safeTransfer(user, amountWithFee);
                delete userQuota[user][_policyTokenAddress];

                // Accumulate the remaining part that will be collected later
                amountRemaining += amount - amountWithFee;
            } else continue;
        }
    }

    /**
     * @notice Generate the policy token name
     * @param _tokenName Name of the stike token (BTC, ETH, AVAX...)
     * @param _decimals Decimals of the name generation (0,1=>1, 2=>2)
     * @param _strikePrice Strike price of the policy (18 decimals)
     * @param _isCall The policy's payoff is triggered when higher(true) or lower(false)
     * @param _round Round of the policy, named by <month><day> (e.g. 0320, 1215)
     */
    function _generateName(
        string memory _tokenName,
        uint256 _decimals,
        uint256 _strikePrice,
        bool _isCall,
        string memory _round
    ) public pure returns (string memory) {
        // The direction is "H"(Call) or "L"(Put)
        string memory direction = _isCall ? "H" : "L";

        // Integer part of the strike price (12e18 => 12)
        uint256 intPart = _strikePrice / 1e18;
        require(intPart > 0, "Invalid int part");

        // Decimal part of the strike price (1234e16 => 34)
        // Can not start with 0 (e.g. 1204e16 => 0 this is incorrect, will revert in next step)
        uint256 decimalPart = _frac(_strikePrice) / (10**(18 - _decimals));
        if (_decimals >= 2)
            require(decimalPart > 10**(_decimals - 1), "Invalid decimal part");

        // Combine the string
        string memory name = string(
            abi.encodePacked(
                _tokenName,
                "_",
                intPart.uintToString(),
                ".",
                decimalPart.uintToString(),
                "_",
                direction,
                "_",
                _round
            )
        );
        return name;
    }

    function _frac(uint256 x) internal pure returns (uint256 result) {
        uint256 SCALE = 1e18;
        assembly {
            result := mod(x, SCALE)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

/**
 * @dev String operations.
 */
library StringsUtils {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @notice Bytes to string (not human-readable form)
     * @param _bytes Input bytes
     * @return stringBytes String form of the bytes
     */
    function byToString(bytes32 _bytes) internal pure returns (string memory) {
        return uintToHexString(uint256(_bytes), 32);
    }

    /**
     * @notice Transfer address to string (not change the content)
     * @param _addr Input address
     * @return stringAddress String form of the address
     */
    function addressToString(address _addr)
        internal
        pure
        returns (string memory)
    {
        return uintToHexString(uint256(uint160(_addr)), 20);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function uintToString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function uintToHexString(uint256 value)
        internal
        pure
        returns (string memory)
    {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return uintToHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function uintToHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "./Context.sol";

/**
 * @dev The owner can be set during deployment, not default to be msg.sender
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address _initialOwner) {
        _transferOwnership(_initialOwner);
    }

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @notice Leaves the contract without owner. It will not be possible to call
     *         `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * @dev    Renouncing ownership will leave the contract without an owner,
     *         thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * @dev    Can only be called by the current owner.
     * @param  newOwner Address of the new owner
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * @dev    Internal function without access restriction.
     * @param  newOwner Address of the new owner
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IERC20Decimals {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface IPriceGetter {
    function getPriceFeedAddress(string memory _tokenName)
        external
        view
        returns (address);

    function setPriceFeed(string memory _tokenName, address _feedAddress)
        external;

    function getLatestPrice(string memory _tokenName)
        external
        returns (uint256 _price);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface INaughtyFactory {
    function getPairAddress(address _tokenAddress1, address _tokenAddress2)
        external
        view
        returns (address);

    function deployPolicyToken(
        string memory _policyTokenName,
        uint256 _decimals
    ) external returns (address);

    function deployPool(
        address _policyTokenAddress,
        address _stablecoin,
        uint256 _deadline,
        uint256 _feeRate
    ) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INPPolicyToken is IERC20 {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

interface INaughtyRouter {
    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityWithUSD(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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

// SPDX-License-Identifier: GPL-3.0-or-later
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.10;

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