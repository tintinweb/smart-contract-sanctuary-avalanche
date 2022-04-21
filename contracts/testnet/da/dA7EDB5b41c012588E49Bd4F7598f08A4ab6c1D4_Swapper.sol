/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-21
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

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

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferAVAX(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: AVAX_TRANSFER_FAILED");
    }
}

interface IPangolinRouter {
    function WAVAX() external pure returns (address);
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
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
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Swapper {
    IPangolinRouter private PangolinRouter;
    address public WAVAX;
    address public theWell;
    IERC20 public USDT;
    IERC20 public splashToken;
    IERC20 public LPToken;

    constructor(address _pangolinRouterAddress, address _USDTAddress, address _splashAddress, address _theWellAddress, address _LPAddress) {
        PangolinRouter = IPangolinRouter(_pangolinRouterAddress);
        USDT = IERC20(_USDTAddress);
        splashToken = IERC20(_splashAddress);
        WAVAX = PangolinRouter.WAVAX();
        theWell = _theWellAddress;
        LPToken = IERC20(_LPAddress);
    }
    function swapUSDTforAVAX(uint256 _amount) external {
        address[] memory _path = new address[](2);
        _path[0] = address(USDT);
        _path[1] = WAVAX;
        PangolinRouter.swapExactTokensForAVAX(_amount,
        0,
        _path,
        address(this),
        block.timestamp);
    }
    function swapAVAXforUSDT() external {
        // address[] memory _path = new address[](2);
        // _path[0] = WAVAX;
        // _path[1] = address(USDT);
        // uint256 _fees = msg.value * 10 / 100;
        // uint256 _amount = msg.value * 90 / 100;
        
        // PangolinRouter.swapExactAVAXForTokens{value: _amount}(
        // 0,
        // _path,
        // address(this),
        // block.timestamp);
    }
    function swapUSDTtoLP(uint256 _amount) external {
        require(_amount > 0, "USDT value should be greater than 0");
        USDT.transferFrom(msg.sender, address(this), _amount);
        uint256 half = _amount / 2;
        USDT.approve(address(PangolinRouter), _amount);
        swapUSDTToSplash(half);
        // uint256 tokenAmount = splashToken.balanceOf(address(this));
        // splashToken.approve(address(PangolinRouter), tokenAmount);
        // addLP(half, tokenAmount);
        // LPToken.transfer(msg.sender, LPToken.balanceOf(address(this)));
    }
    function sendAvaxToContract() private {
        (bool success, ) = theWell.call{value:address(this).balance}("");
        assert(success);
        require(splashToken.transfer(theWell, splashToken.balanceOf(address(this))));
        // address[] memory _path = new address[](2);
        // _path[0] = WAVAX;
        // _path[1] = address(USDT);
        // uint256 _fees = msg.value * 10 / 100;
        // uint256 _amount = msg.value * 90 / 100;
        // payable(msg.sender).transfer(msg.value);
        // PangolinRouter.swapExactAVAXForTokens{value: _amount}(
        // 0,
        // _path,
        // address(this),
        // block.timestamp);
    }
    function swapUSDTToSplash(uint256 amount) internal {
        // SWAP split % of ETH input to token
        address[] memory path = new address[](2);
        path[0] = address(USDT);
        // path[1] = WAVAX;
        // path[2] = _tokenAddress;
        path[1] = address(splashToken);
        PangolinRouter.swapExactTokensForTokens(
            amount,
            1,
            path,
            address(this),
            block.timestamp + 15 minutes
        );
    }
    function addLP(uint256 _USDTAmount, uint256 _tokenAmount) internal {
        // add the liquidity
        PangolinRouter.addLiquidity(
            address(USDT),
            address(splashToken),
            _USDTAmount,
            _tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp + 15 minutes
        );
    }
    function quoteUSDTforAVAX(uint256 _amount) public view returns(uint256[] memory amounts){
        address[] memory _path = new address[](2);
        _path[0] = address(USDT);
        _path[1] = WAVAX;
        amounts = PangolinRouter.getAmountsOut(_amount, _path);
    }
    function quoteAVAXforUSDT(uint256 _amount) public view returns(uint256[] memory amounts){
        address[] memory _path = new address[](2);
        _path[0] = WAVAX;
        _path[1] = address(USDT); 
        amounts = PangolinRouter.getAmountsOut(_amount, _path);
    }
    function USDTBalanceContract() public view returns (uint256 balance){
        balance = USDT.balanceOf(address(this));
    }
    function AVAXBalanceContract() public view returns (uint256 balance){
        balance = address(this).balance;
    }
    function SplashBalanceContract() public view returns (uint256 balance){
        balance = splashToken.balanceOf(address(this));
    }
    function LPBalanceContract() public view returns (uint256 balance){
        balance = LPToken.balanceOf(address(this));
    }
    function USDTBalanceSender() public view returns (uint256 balance){
        balance = USDT.balanceOf(msg.sender);
    }
    function AVAXBalanceSender() public view returns (uint256 balance){
        balance = msg.sender.balance;
    }
    function SplashBalanceSender() public view returns (uint256 balance){
        balance = splashToken.balanceOf(msg.sender);
    }
    function LPBalanceSender() public view returns (uint256 balance){
        balance = LPToken.balanceOf(msg.sender);
    }
}

//PangolinRouterAddress : 0x2d99abd9008dc933ff5c0cd271b88309593ab921
//USDTAddress : 0x5e666D284815C9C2f00fA7Ac8786abfB806954FC
//SplashAddress : 0xde83309d30524eA6F9526AaE4E3c2D93cA87f1e9
//theWellAddress : 0x8D74f9A1FEABBf699288dE67a4948089Bc66f03F
//LPAddress : 0x919D6510Fbf0E792Ccc6fAc26e864D45D1E197Da