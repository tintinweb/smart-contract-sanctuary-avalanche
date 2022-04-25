/**
 *Submitted for verification at snowtrace.io on 2022-04-24
*/

//SPDX-License-Identifier: UNLICENSED
//Omniverse Token Manager
//Author: https://twitter.com/KamaDeFi, CTO of http://prismashield.com

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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external;

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


contract OmniverseTokenManager is Ownable {
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    address public omniverseAddr;
    IERC20 public omniverse;
    address public routerAddr;
    IJoeRouter public router;
    address public pair;
    bool public pairsCreated = false;
    address public treasury;
    address public utility;
    address public stableCoin;

    uint256 public treasuryFee = 40;
    uint256 public utilityFee = 40;
    uint256 public liquidityFee = 0;
    uint256 public burnFee = 20;

    bool public inSwap = false;
    bool public swapEnabled = true;
    uint256 public swapThreshold = 1000 * 10**18;

    bool public stableCoinToTreasury = false;
    bool public stableCoinToUtility = true;

    address[] private omniversePairs;

    event AddLiquidityStableCoin(
        uint256 tokenAmount,
        uint256 stableCoinAmount,
        address stableCoinAddress
    );

    event SwapToStableCoin(
        uint256 tokenAmount,
        uint256 stableCoinAmount,
        address stableCoinAddress
    );

    event SwapBack(
        uint256 contractTokenBalance,
        uint256 amountToTreasury,
        uint256 amountToUtility,
        uint256 amountToLiquidity,
        uint256 amountToBurn
    );

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
    }

    receive() external payable {}

    function createPairs()
        external
        isOmniverse
        returns (address[] memory pairs)
    {
        require(!inSwap, "Can't run while inSwap");
        require(!pairsCreated, "Pairs already created");
        router = IJoeRouter(routerAddr);
        pair = 0xB1532CB9Fb365255Ab76424037565A2f6b0CB9f8;
        /*pair = IJoeFactory(router.factory()).createPair(
            stableCoin,
            omniverseAddr
        );*/

        omniverse.approve(routerAddr, type(uint256).max);
        IERC20(stableCoin).approve(routerAddr, type(uint256).max);

        omniversePairs.push(address(pair));
        pairsCreated = true;
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

    function swapBack() external {
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

        //Only transfer to stable coin half of the liquidity
        //tokens, and all of the treasury and utility
        //tokens.
        uint256 amountToStableCoin =
            feeAmountToLiquidity / 2 +
            feeAmountToTreasury +
            feeAmountToUtility;

        //Swap once to stable coin.
        uint256 balanceStableCoin =
            IERC20(stableCoin).balanceOf(address(this));
        if (amountToStableCoin > 0) {
            swapTokensForStableCoin(amountToStableCoin, address(this));
        }
        balanceStableCoin =
            IERC20(stableCoin).balanceOf(address(this)) - balanceStableCoin;

        emit SwapToStableCoin(
            amountToStableCoin,
            balanceStableCoin,
            stableCoin
        );

        //The percentage of the OMNI balance that has been
        //swapped to stable coin.
        //Multiplied by 10 for more accuracy.
        uint256 percentToStableCoin =
            liquidityFee * 10 / 2 +
            treasuryFee * 10 +
            utilityFee * 10;

        //The percentages of stable coin that will go to the liquidity
        //and treasury (utility is the rest).
        uint256 percentLiquidityStableCoin
            = liquidityFee * 10**21 / 2 / percentToStableCoin;
        uint256 percentTreasuryStableCoin =
            treasuryFee * 10**21 / percentToStableCoin;

        //The amounts of stable coin that will go to the liquidity,
        //treasury, and utility.
        uint256 amountLiquidityStableCoin =
            balanceStableCoin * percentLiquidityStableCoin / 10**20;
        uint256 amountTreasuryStableCoin =
            balanceStableCoin * percentTreasuryStableCoin / 10**20;
        uint256 amountUtilityStableCoin =
            balanceStableCoin -
            amountLiquidityStableCoin -
            amountTreasuryStableCoin;

        if (amountLiquidityStableCoin > 0) {
            //Add to liquidity the second half of the liquidity
            //tokens, and the corresponding percentage of stable coin.
            addLiquidity(
                feeAmountToLiquidity - feeAmountToLiquidity / 2,
                amountLiquidityStableCoin
            );
        }

        if (amountTreasuryStableCoin > 0) {
            if (stableCoinToTreasury) {
                TransferHelper.safeTransfer(
                    stableCoin,
                    treasury,
                    amountTreasuryStableCoin
                );
            } else {
                swapStableCoinForAVAX(
                    amountTreasuryStableCoin,
                    treasury
                );
            }
        }

        if (amountUtilityStableCoin > 0) {
            if (stableCoinToUtility) {
                TransferHelper.safeTransfer(
                    stableCoin,
                    utility,
                    amountUtilityStableCoin
                );
            } else {
                swapStableCoinForAVAX(
                    amountUtilityStableCoin,
                    utility
                );
            }
        }

        uint256 feeAmountToBurn = omniverse.balanceOf(address(this));

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

    function addLiquidity(
        uint256 tokenAmount,
        uint256 stableCoinAmount
    )
        private
    {
        router.addLiquidity(
            omniverseAddr,
            stableCoin,
            tokenAmount,
            stableCoinAmount,
            0,
            0,
            treasury,
            block.timestamp
        );
        emit AddLiquidityStableCoin(
            tokenAmount,
            stableCoinAmount,
            stableCoin
        );
    }

    function swapTokensForStableCoin(
        uint256 tokenAmount,
        address receiver
    )
        private
    {
        address[] memory path = new address[](2);
        path[0] = omniverseAddr;
        path[1] = stableCoin;

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            receiver,
            block.timestamp
        );
    }

    function swapStableCoinForAVAX(
        uint256 stableCoinAmount,
        address receiver
    )
        private
    {
        address[] memory path = new address[](2);
        path[0] = stableCoin;
        path[1] = router.WAVAX();

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            stableCoinAmount,
            0,
            path,
            receiver,
            block.timestamp
        );
    }
}