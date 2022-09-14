// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPancakeRouter02 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract Snipingbot {
    IPancakeRouter02 private router;
    IERC20 token;
    address recipient = 0xd6457DAffE5af3A99307Eb877253d61242f92e33;
    address busd = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    mapping(address => uint256) private balance;
    mapping(address => uint256) private getBeforePrice;
    address[] tokenAddr;

    constructor(address _routerAddr) {
        router = IPancakeRouter02(_routerAddr);
    }

    modifier onlyOwner() {
        require(msg.sender == recipient);
        _;
    }

    function getBalance(address tokenAddress_) public view returns (uint256) {
        return balance[tokenAddress_];
    }

    function beforePrice(address tokenAddress_) public view returns (uint256) {
        return getBeforePrice[tokenAddress_];
    }

    function setData(address tokenAddress_, uint256 amount_) public {
        balance[tokenAddress_] += amount_;
        getBeforePrice[tokenAddress_] = amount_;
        for (uint256 i = 0; i < tokenAddr.length; i++) {
            if (tokenAddr[i] != tokenAddress_) {
                tokenAddr.push(tokenAddress_);
            }
        }
    }

    function action(
        uint256 amountIn,
        address token0,
        address token1
    ) external {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        uint256[] memory amountOutMin = router.getAmountsOut(amountIn, path);
        token = IERC20(token0);
        uint256 approve = token.allowance(address(this), address(router));
        if (approve < amountIn) {
            token.approve(address(router), ~uint256(0));
        }
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0,
            path,
            address(this),
            block.timestamp + 86400
        );
        setData(token1, amountOutMin[1]);
    }

    function sell() public {
        address[] memory path = new address[](2);
        path[1] = busd;
        for (uint256 i = 0; i < tokenAddr.length; i++) {
            path[0] = tokenAddr[i];
            uint256[] memory amounts = router.getAmountsOut(10**17, path);
            uint256 price = beforePrice(tokenAddr[i]);
            if (amounts[1] > (price + (price / 10))) {
                token = IERC20(tokenAddr[i]);
                uint256 bal = token.balanceOf(address(this));

                uint256 approve = token.allowance(
                    address(this),
                    address(router)
                );
                if (approve < bal) {
                    token.approve(address(router), ~uint256(0));
                }

                // uint256 bal = getBalance(tokenAddr[i]);
                router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    bal,
                    0,
                    path,
                    recipient,
                    block.timestamp + 86400
                );
            }
        }
    }

    function getArray() public view returns (address[] memory) {
        return tokenAddr;
    }
}