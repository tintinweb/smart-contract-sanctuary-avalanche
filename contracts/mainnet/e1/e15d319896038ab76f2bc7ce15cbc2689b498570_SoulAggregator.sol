/**
 *Submitted for verification at snowtrace.io on 2022-09-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address spender, address to, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    // EIP 2612
    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IDex {
    function swapTokensForExactAVAX(
        uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external returns (uint[] memory amounts);
    function swapTokensForExactETH(
        uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external returns (uint[] memory amounts);
    function swapETHForExactTokens(
        uint amountOut, address[] calldata path, address to, uint deadline)
        external payable returns (uint[] memory amounts);
    function swapAVAXForExactTokens(
        uint amountOut, address[] calldata path, address to, uint deadline)
        external payable returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract SoulAggregator {
    // soulSwap[0] && joeSwap[1]
    IDex[2] public Dexes;
    IERC20 public immutable usdc = IERC20(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E);
    address public immutable wavaxAddress = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    IDex public joeSwap = IDex(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    IDex public soulSwap = IDex(0xa4594460A9d3D41e8B85542D34E23AdAbc3c86Ef);

    /// @notice USDCBought event emitted on successful AVAX to USDC swap. 
    event USDCBought(
        uint usdcAmountBought, 
        uint avaxAmountSold,
        address dex, 
        uint nextBestUsdcOutput
    );

    /// @notice USDCSold event emitted on successful USDC to AVAX swap.    
    event USDCSold(
        uint avaxAmountBought,
        uint usdcAmountSold, 
        address dex, 
        uint nextBestAvaxOutput
    );

    constructor () {
        Dexes[0] = IDex(soulSwap);
        Dexes[1] = IDex(joeSwap);
    }

    // recieves: refunded ETH from either dex.
    receive() external payable {}

    // returns: index of exchange with the highest output amount and the output amount from each exchange in an array.
    function getOutputAmounts(uint amountIn, address[] calldata path) 
        public view returns(uint8 optimalDex, uint[] memory amounts){
            // creates: new in memory array of length 2
            amounts = new uint[] (2);
            // fetches: output amounts from each exchange
            amounts[0] = (Dexes[0].getAmountsOut(amountIn, path))[1];
            amounts[1] = (Dexes[1].getAmountsOut(amountIn, path))[1];
            // [if] joeSwap > than soulSwap amount, [then] swap order of amounts[] & set dex w/greater output i to 1.
            if(amounts[1] > amounts[0]) {
                amounts[0] = amounts[1];
                amounts[1] = (Dexes[0].getAmountsOut(amountIn, path))[1];
                optimalDex = 1;
            }
    }
    function buyUSDCAtBestPrice(uint deadline, address[] calldata path) external payable {
        require(path[0] == wavaxAddress && path[1] == address(usdc), "Wrong token pair array");
        // get dex with best USDC price and output amounts for each exchange.
        (uint8 dex, uint[] memory stableAmounts) = getOutputAmounts(msg.value, path);
        // route trade to dex with best USDC price.
        Dexes[dex] == joeSwap 
            ? Dexes[dex].swapAVAXForExactTokens{ value: msg.value }(stableAmounts[0], path, msg.sender, deadline)
            : Dexes[dex].swapETHForExactTokens{ value: msg.value }(stableAmounts[0], path, msg.sender, deadline);
        // refund leftover ETH to user.
        payable(msg.sender).transfer(address(this).balance);
        emit USDCBought(stableAmounts[0], msg.value, address(Dexes[dex]), stableAmounts[1]);
    }
    function sellUSDCAtBestPrice(uint stableAmount, uint deadline, address[] calldata path) external {
        require(path[1] == wavaxAddress && path[0] == address(usdc), "Wrong token pair array");
        require(usdc.balanceOf(msg.sender) >= stableAmount, "Error, can't sell more USDC than owned");
        // transfer the usdc amount from the user to this contract. 
        require(usdc.transferFrom(msg.sender, address(this), stableAmount));
        // get dex with best ETH price and output amounts for each exchange
        (uint8 dex, uint[] memory nativeAmounts) = getOutputAmounts(stableAmount, path);
        // approve dex with best ETH price to spend USDC tokens
        require(usdc.approve(address(Dexes[dex]), stableAmount), 'approve failed.');
        // route trade to dex with best ETH price
        Dexes[dex] == joeSwap 
            ? Dexes[dex].swapTokensForExactAVAX(nativeAmounts[0], stableAmount, path, msg.sender, deadline)
            : Dexes[dex].swapTokensForExactETH(nativeAmounts[0], stableAmount, path, msg.sender, deadline);
        emit USDCSold(nativeAmounts[0], stableAmount, address(Dexes[dex]), nativeAmounts[1]);
    }
}