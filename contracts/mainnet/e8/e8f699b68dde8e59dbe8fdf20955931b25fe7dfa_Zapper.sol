//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC20.sol";
import "./IUniswapV2Router02.sol";

interface IXGrape {
    function mintWithBacking(uint256 numTokens, address recipient) external returns (uint256);
}

interface IVault is IERC20 {
    function deposit(uint amount) external;
}

contract Zapper {

    // constants
    IVault public constant Underlying = IVault(0x0dA1DC567D81925cFf22Df74C6b9e294E9E1c3A5);
    IUniswapV2Router02 public constant router = IUniswapV2Router02(0xC7f372c62238f6a5b79136A9e5D16A2FD7A3f0F5);
    address public constant LP = 0x9076C15D7b2297723ecEAC17419D506AE320CbF1;
    address public constant MIM = 0x130966628846BFd36ff31a822705796e8cb8C18D;
    address public constant GRAPE = 0x5541D83EFaD1f281571B343977648B75d95cdAC2;

    // XGrape Token
    address public immutable XGRAPE;

    constructor(address XGRAPE_) {
        XGRAPE = XGRAPE_;
    }

    receive() external payable {
        
        // convert AVAX into underlying
        _convertTokenToUnderlying(address(0));

        // transfer AVAX back to XGRAPE
        Underlying.transfer(XGRAPE, Underlying.balanceOf(address(this)));

        // refund dust
        _refundDust(msg.sender);
    }

    function zapWithAvax(uint256 minOut) external payable {

        // convert token to Underlying
        _convertTokenToUnderlying(address(0));
        
        // require minOut
        uint256 bal = Underlying.balanceOf(address(this));
        require(
            bal >= minOut,
            'Min LP Out'
        );

        // approve Miner for balance
        Underlying.approve(XGRAPE, bal);

        // deposit for sender
        IXGrape(XGRAPE).mintWithBacking(bal, msg.sender);

        // refund dust
        _refundDust(msg.sender);
    }

    function zap(address token_, uint256 amount, uint256 minOut) external {

        // transfer in `amount` of `token`
        _transferIn(token_, amount);

        if (token_ != address(Underlying)) {
            if (token_ == LP) {
                // convert LP into underlying
                _depositIntoVault();
            } else {
                // convert token to Underlying
                _convertTokenToUnderlying(token_);
            }
        }

        // require minOut
        uint256 bal = Underlying.balanceOf(address(this));
        require(
            bal >= minOut,
            'Min LP Out'
        );

        // approve Miner for balance
        Underlying.approve(XGRAPE, bal);

        // deposit for sender
        IXGrape(XGRAPE).mintWithBacking(bal, msg.sender);

        // refund dust
        _refundDust(msg.sender);
    }

    function _convertTokenIntoTokensForLP(address token_) internal {

        if ( token_ == MIM || token_ == GRAPE ) {
            
            // swap half token_ for other token
            uint256 amount = IERC20(token_).balanceOf(address(this)) / 2;
            
            // approve of swap
            IERC20(token_).approve(address(router), amount);

            // token we are swapping for
            address swapToToken = token_ == MIM ? GRAPE : MIM;

            // Swap Path
            address[] memory path = new address[](2);
            path[0] = token_;
            path[1] = swapToToken;

            // Swap The Tokens
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount, 0, path, address(this), block.timestamp + 10
            );

            // gas savings
            delete path;

        } else if (token_ == address(0)) {

            // Swap Path WETH -> MIM
            address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = MIM;

            // swap balance into MIM, then swap MIM into Grape
            router.swapExactETHForTokens{
                value: address(this).balance
            }(0, path, address(this), block.timestamp + 10);

            // clear memory
            delete path;

            // swap MIM into GRAPE
            _convertTokenIntoTokensForLP(MIM);

        } else {
            
            // balance
            uint256 amount = IERC20(token_).balanceOf(address(this));

            // approve of swap
            IERC20(token_).approve(address(router), amount);

            // Swap Path
            address[] memory path = new address[](2);
            path[0] = token_;
            path[1] = MIM;

            // Swap The Tokens
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount, 0, path, address(this), block.timestamp + 10
            );

            // gas savings
            delete path;

            // swap MIM into GRAPE
            _convertTokenIntoTokensForLP(MIM);
        }
    }

    function _convertTokenToUnderlying(address token_) internal {

        // convert token to LP token
        _convertTokenIntoTokensForLP(token_);

        // pair liquidity
        _pairLiquidity();

        // deposit liquidity token into vault
        _depositIntoVault();
    }

    function _depositIntoVault() internal {
        // stake all LP balance Into Vault
        uint256 bal = IERC20(LP).balanceOf(address(this));
        IERC20(LP).approve(address(Underlying), bal);
        Underlying.deposit(bal);
    }

    function _pairLiquidity() internal {

        // fetch balances
        uint256 bal0 = IERC20(MIM).balanceOf(address(this));
        uint256 bal1 = IERC20(GRAPE).balanceOf(address(this));

        // approve tokens
        IERC20(MIM).approve(address(router), bal0);
        IERC20(GRAPE).approve(address(router), bal1);

        // add liquidity
        router.addLiquidity(
            MIM, 
            GRAPE, 
            bal0,
            bal1,
            0,
            0,
            address(this),
            block.timestamp + 10
        );
    }

    function _refundDust(address recipient) internal {
        
        // refund dust
        uint bal0 = IERC20(MIM).balanceOf(address(this));
        uint bal1 = IERC20(GRAPE).balanceOf(address(this));
        if (bal0 > 0) {
            IERC20(MIM).transfer(
                recipient,
                bal0
            );
        }
        if (bal1 > 0) {
            IERC20(GRAPE).transfer(
                recipient,
                bal1
            );
        }
    }

    function _transferIn(address token, uint256 amount) internal {
        require(
            IERC20(token).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            'Failure Transfer From'
        );
    }
}