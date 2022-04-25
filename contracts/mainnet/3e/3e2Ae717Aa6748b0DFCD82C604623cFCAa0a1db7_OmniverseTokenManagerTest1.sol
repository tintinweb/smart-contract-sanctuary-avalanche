/**
 *Submitted for verification at snowtrace.io on 2022-04-22
*/

//SPDX-License-Identifier: UNLICENSED
//Omniverse Token Manager
//Author: https://twitter.com/KamaDeFi, CTO of https://prismashield.com

pragma solidity 0.8.13;


library TransferHelper {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferAVAX(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: AVAX_TRANSFER_FAILED");
    }
}


interface IJoeFactory {
    function createPair(address tokenA, address tokenB)
        external returns (address pair);
}


interface IJoeRouter {
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
        returns (uint256 amountToken, uint256 amountAVAX, uint256 liquidity);

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external;

    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);
}


interface IERC20 {
    function transfer(address to, uint256 value)
        external
        returns (bool);

    function approve(address spender, uint256 value) external returns (bool);    

    function balanceOf(address who) external view returns (uint256);
}


library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage self, address account) internal {
        require(!has(self, account), "Roles: account already has role");
        self.bearer[account] = true;
    }

    function remove(Role storage self, address account) internal {
        require(has(self, account), "Roles: account does not have role");
        self.bearer[account] = false;
    }

    function has(Role storage self, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return self.bearer[account];
    }
}


contract SwapBackRole {	
    using Roles for Roles.Role;	

    Roles.Role private swappers;

    event SwapperAdded(address indexed account);	
    event SwapperRemoved(address indexed account);	

    modifier onlySwapper() {	
        require(
            isSwapper(msg.sender),
            "SwapperRole: caller does not have the Swapper role"
        );	
        _;	
    }

    function renounceSwapper() public {	
        removeSwapperInternal(msg.sender);	
    }

    function isSwapper(address addr) public view returns (bool) {	
        return swappers.has(addr);	
    }

    function addSwapperInternal(address addr) internal {	
        swappers.add(addr);	
        emit SwapperAdded(addr);	
    }

    function removeSwapperInternal(address addr) internal {	
        swappers.remove(addr);	
        emit SwapperRemoved(addr);	
    }
}


contract Ownable {
    address private owner_;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner_ = msg.sender;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner_);
        owner_ = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        transferOwnershipInternal(newOwner);
    }

    function owner() public view returns (address) {
        return owner_;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner_;
    }

    function transferOwnershipInternal(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner_, newOwner);
        owner_ = newOwner;
    }
}


contract OmniverseTokenManagerTest1 is Ownable, SwapBackRole {
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    address public omniverseAddr;
    IERC20 public omniverse;
    address public routerAddr;
    IJoeRouter public router;
    address[] public omniversePairs;
    bool public pairsCreated = false;
    address public treasury;
    address public utility;
    address public stableCoin;

    uint256 public treasuryFee = 40;
    uint256 public utilityFee = 30;
    uint256 public liquidityFee = 10;
    uint256 public burnFee = 20;

    bool public inSwap = false;
    bool public swapEnabled = true;
    uint256 public swapThreshold = 150000 * 10**18;

    bool public stableCoinToTreasury = false;
    bool public stableCoinToUtility = true;

    event AddLiquidityAVAX(
        uint256 tokenAmount,
        uint256 avaxAmount
    );

    event SwapToAVAX(
        uint256 tokenAmount,
        uint256 avaxAmount
    );

    event SwapBack(
        uint256 contractTokenBalance,
        uint256 amountToTreasury,
        uint256 amountToUtility,
        uint256 amountToLiquidity,
        uint256 amountToBurn
    );

    event LogCreatePairs(string message);

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier isOmniverse() {
        require(
            msg.sender == omniverseAddr,
            "Can only be called by Omniverse"
        );
        _;
    }

    constructor(
        address ownerAddr,
        address omniverseAddress,
        address routerAddress,
        address treasuryReceiver,
        address utilityReceiver,
        address stableCoinAddr
    )
    {
        transferOwnershipInternal(ownerAddr);
        omniverseAddr = omniverseAddress;
        omniverse = IERC20(omniverseAddr);
        routerAddr = routerAddress;
        treasury = treasuryReceiver;
        utility = utilityReceiver;
        stableCoin = stableCoinAddr;

        addSwapperInternal(ownerAddr);
    }

    receive() external payable {}

    function createPairs()
        external
        isOmniverse
        returns (address[] memory pairs)
    {
        emit LogCreatePairs("Entered createPairs");
        require(!inSwap, "Can't run while inSwap");
        emit LogCreatePairs("Cool, not in swap as expected");
        require(!pairsCreated, "Pairs already created");
        emit LogCreatePairs("Cool, pairs not created yet as expected");
        router = IJoeRouter(routerAddr);
        address pair = IJoeFactory(router.factory()).createPair(
            router.WAVAX(),
            omniverseAddr
        );

        omniverse.approve(routerAddr, type(uint256).max);
        emit LogCreatePairs("Cool, successfully approved");

        omniversePairs.push(address(pair));
        emit LogCreatePairs("Cool, added pair to omniversePairs");
        pairsCreated = true;
        emit LogCreatePairs("Cool, pairsCreated set to true");
        return omniversePairs;
    }

    function setFeeReceivers(
        address treasuryReceiver,
        address utilityReceiver,
        address stableCoinAddr
    )
        external
        onlyOwner
    {
        require(!inSwap, "Can't run while inSwap");
        treasury = treasuryReceiver;
        utility = utilityReceiver;
        stableCoin = stableCoinAddr;
    }

    function setFees(
        uint256 treasuryPercent,
        uint256 utilityPercent,
        uint256 liquidityPercent,
        uint256 burnPercent
    )
        external
        onlyOwner
    {
        require(!inSwap, "Can't run while inSwap");
        uint256 sum =
            treasuryPercent +
            utilityPercent +
            liquidityPercent +
            burnPercent;
        require(sum == 100, "Sum of percentages doesn't add to 100");

        treasuryFee = treasuryPercent;
        utilityFee = utilityPercent;
        liquidityFee = liquidityPercent;
        burnFee = burnPercent;
    }

    function setSwapBackSettings(bool enabled, uint256 threshold)
        external
        onlyOwner
    {
        require(!inSwap, "Can't run while inSwap");
        swapEnabled = enabled;
        swapThreshold = threshold;
    }

    function setStableCoinToTreasury(bool enabled) external onlyOwner {
        require(!inSwap, "Can't run while inSwap");
        stableCoinToTreasury = enabled;
    }

    function setStableCoinToUtility(bool enabled) external onlyOwner {
        require(!inSwap, "Can't run while inSwap");
        stableCoinToUtility = enabled;
    }

    function addSwapper(address addr) external onlyOwner {
        addSwapperInternal(addr);
    }
	
    function removeSwapper(address addr) external onlyOwner {
        removeSwapperInternal(addr);
    }

    function swapBack() external onlySwapper {
        require(!inSwap, "Already inSwap");
        require(swapEnabled, "swapBack is disabled");

        uint256 contractBalance = omniverse.balanceOf(address(this));
        require(
            contractBalance >= swapThreshold,
            "Below swapBack threshold"
        );

        swapBackPrivate(contractBalance);
    }

    function rescueAVAX(uint256 amount, address receiver)
        external
        onlyOwner
    {
        require(
            amount <= address(this).balance,
            "Amount larger than what's in the contract"
        );
        TransferHelper.safeTransferAVAX(receiver, amount);
    }

    function rescueERC20Token(
        address tokenAddr,
        uint256 tokens,
        address receiver
    )
        external
        onlyOwner
    {
        require(
            tokens <= IERC20(tokenAddr).balanceOf(address(this)),
            "Amount larger than what's in the contract"
        );
        TransferHelper.safeTransfer(tokenAddr, receiver, tokens);
    }

    //This is to be used as the resolver function in Gelato
    //for swapBack.
    function shouldSwapback()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        canExec =
            !inSwap &&
            swapEnabled &&
            omniverse.balanceOf(address(this)) >= swapThreshold;
        execPayload = abi.encodeWithSelector(this.swapBack.selector);
    }

    function swapBackPrivate(uint256 contractBalance) swapping private {
        uint256 feeAmountToLiquidity =
            contractBalance * liquidityFee / 100;
        uint256 feeAmountToTreasury =
            contractBalance * treasuryFee / 100;
        uint256 feeAmountToUtility =
            contractBalance * utilityFee / 100;
        uint256 feeAmountToBurn =
            contractBalance -
            feeAmountToLiquidity -
            feeAmountToTreasury -
            feeAmountToUtility;

        //Only transfer to AVAX half of the liquidity
        //tokens, and all of the treasury and utility
        //tokens.
        uint256 amountToAVAX =
            feeAmountToLiquidity / 2 +
            feeAmountToTreasury +
            feeAmountToUtility;

        //Swap once to AVAX.
        uint256 balanceAVAX = address(this).balance;
        if (amountToAVAX > 0) {
            swapTokensForAVAX(amountToAVAX, address(this));
        }
        balanceAVAX = address(this).balance - balanceAVAX;

        emit SwapToAVAX(amountToAVAX, balanceAVAX);

        //The percentage of the OMNI balance that has been
        //swapped to AVAX.
        //Multiplied by 10**5 for more accuracy.
        uint256 percentToAVAX =
            liquidityFee * 10**5 / 2 +
            treasuryFee * 10**5 +
            utilityFee * 10**5;

        //The percentages of AVAX that will go to the liquidity
        //and treasury (utility is the rest).
        uint256 percentLiquidityAVAX = liquidityFee * 10**7 / 2 / percentToAVAX;
        uint256 percentTreasuryAVAX = treasuryFee * 10**7 / percentToAVAX;

        //The amounts of AVAX that will go to the liquidity,
        //treasury, and utility.
        uint256 amountLiquidityAVAX =
            balanceAVAX * percentLiquidityAVAX / 10**7;
        uint256 amountTreasuryAVAX =
            balanceAVAX * percentTreasuryAVAX / 10**7;
        uint256 amountUtilityAVAX =
            balanceAVAX - amountLiquidityAVAX - amountTreasuryAVAX;

        if (amountLiquidityAVAX > 0) {
            //Add to liquidity the second half of the liquidity
            //tokens, and the corresponding percentage of AVAX.
            addLiquidity(
                feeAmountToLiquidity - feeAmountToLiquidity / 2,
                amountLiquidityAVAX
            );
        }

        if (amountTreasuryAVAX > 0) {
            if (stableCoinToTreasury) {
                swapAVAXForStableCoin(amountTreasuryAVAX, treasury);
            } else {
                TransferHelper.safeTransferAVAX(treasury, amountTreasuryAVAX);
            }
        }

        if (amountUtilityAVAX > 0) {
            if (stableCoinToUtility) {
                swapAVAXForStableCoin(amountUtilityAVAX, utility);
            } else {
                TransferHelper.safeTransferAVAX(utility, amountUtilityAVAX);
            }
        }

        if (feeAmountToBurn > 0) {
            omniverse.transfer(DEAD, feeAmountToBurn);
        }

        emit SwapBack(
            contractBalance,
            feeAmountToTreasury,
            feeAmountToUtility,
            feeAmountToLiquidity,
            feeAmountToBurn
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 avaxAmount) private {
        router.addLiquidityAVAX{value: avaxAmount}(
            omniverseAddr,
            tokenAmount,
            0,
            0,
            treasury,
            block.timestamp
        );
        emit AddLiquidityAVAX(tokenAmount, avaxAmount);
    }

    function swapAVAXForStableCoin(uint256 avaxAmount, address receiver)
        private
    {
        address[] memory path = new address[](2);
        path[0] = router.WAVAX();
        path[1] = stableCoin;

        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{value: avaxAmount}(
            0,
            path,
            receiver,
            block.timestamp
        );
    }

    function swapTokensForAVAX(uint256 tokenAmount, address receiver)
        private
    {
        address[] memory path = new address[](2);
        path[0] = omniverseAddr;
        path[1] = router.WAVAX();

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            receiver,
            block.timestamp
        );
    }
}